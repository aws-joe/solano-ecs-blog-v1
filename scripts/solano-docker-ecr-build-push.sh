#!/bin/bash
# Build and start docker container

SOLANO_LOGFILE="$HOME/results/$TDDIUM_SESSION_ID/session/solano-docker-ecr-build-push.sh.txt"
echo "Starting solano-docker-ecr-build-push.sh" > $SOLANO_LOGFILE
date >> $SOLANO_LOGFILE

# Ensure aws-cli is installed and configured
if [ ! -f $HOME/bin/aws ]; then
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  ./awscli-bundle/install -b $HOME/bin/aws
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
echo "Assigning repository credentials..." >> $SOLANO_LOGFILE
DOCKER_LOGIN=`aws ecr get-login --region $AWS_DEFAULT_REGION` >> $SOLANO_LOGFILE
echo "Finished run of aws get-login." >> $SOLANO_LOGFILE

echo $DOCKER_LOGIN >> $SOLANO_LOGFILE

echo "Performing docker login...." >> $SOLANO_LOGFILE
sudo $DOCKER_LOGIN
echo "Done with docker login." >> $SOLANO_LOGFIL

# Build docker image
echo "Performing docker build." >> $SOLANO_LOGFILE
sudo docker build -t $DOCKER_APP:$TDDIUM_SESSION_ID . >> $SOLANO_LOGFILE
echo "Completed docker build." >> $SOLANO_LOGFILE

#tag image and push to AWS ECR
sudo docker tag ${DOCKER_APP}:${TDDIUM_SESSION_ID} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${DOCKER_APP}:${TDDIUM_SESSION_ID} >> $SOLANO_LOGFILE
echo "Pushing docker image to repository." >> $SOLANO_LOGFILE
sudo docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${DOCKER_APP}:${TDDIUM_SESSION_ID} >> $SOLANO_LOGFILE
echo "Image in repository." >> $SOLANO_LOGFILE

# Start docker container and record ID and IP address
CID=$(sudo docker run -d --expose=80 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${DOCKER_APP}:${TDDIUM_SESSION_ID})
echo $CID > $TDDIUM_REPO_ROOT/container-$TDDIUM_SESSION_ID.cid
IP_ADDR=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CID)
echo $IP_ADDR > $TDDIUM_REPO_ROOT/container-$TDDIUM_SESSION_ID.ip
