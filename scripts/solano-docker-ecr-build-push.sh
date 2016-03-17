#!/bin/bash
# Build and start docker container

#initial version provided by Solano Labs:
#  https://github.com/solanolabs/ci_memes-docker/

set -o errexit -o pipefail # Exit on error

SOLANO_LOGFILE="$HOME/results/$TDDIUM_SESSION_ID/session/solano-docker-ecr-build-push-${TDDIUM_SESSION_ID}.txt"

echo "Starting solano-docker-ecr-build-push.sh" > $SOLANO_LOGFILE
date >> $SOLANO_LOGFILE

# Ensure aws-cli is installed and configured
if [ ! -f $HOME/bin/aws ]; then
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  ./awscli-bundle/install -b $HOME/bin/aws
  echo "Installed AWS CLI" >> $SOLANO_LOGFILE
  which aws >> $SOLANO_LOGFILE
fi
if [ -d $HOME/lib/python2.7/site-packages ]; then
  export PYTHONPATH=$HOME/lib/python2.7/site-packages
fi

# Ensure AWS Variables are available
if [[ -z "$AWS_ACCOUNT_ID" || -z "$AWS_DEFAULT_REGION " ]]; then
	echo "AWS Variables Not Set.  Either AWS_ACCOUNT_ID or AWS_DEFAULT_REGION"
	exit 1
fi

which aws
if [ $? -ne 0 ]; then
	echo "Cannot find aws command."
	exit 1
fi

#Log in to AWS ECR Docker Repository
echo "Requesting AWS ECR credentials."
DOCKER_LOGIN=`aws ecr get-login --region $AWS_DEFAULT_REGION`

echo "Performing docker login."
sudo $DOCKER_LOGIN
#uncomment below to view AWS ECR credentials in log file output:
#echo $DOCKER_LOGIN >> $SOLANO_LOGFILE

# Build docker image
echo "Performing docker build."
sudo docker build -t $DOCKER_APP:$TDDIUM_SESSION_ID .
echo "Completed docker build."

#tag image and push to AWS ECR
sudo docker tag ${DOCKER_APP}:${TDDIUM_SESSION_ID} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${DOCKER_APP}:${TDDIUM_SESSION_ID}

# Pushing docker image to repository
sudo docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${DOCKER_APP}:${TDDIUM_SESSION_ID}
echo "Image uploaded to repository."

echo "Push to AWS ECR Complete" >> $SOLANO_LOGFILE
date >> $SOLANO_LOGFILE
