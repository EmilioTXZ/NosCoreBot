dotnet publish ./src/NosCoreBot -c Release -o ./bin/Docker

DOCKER_ENV=''
DOCKER_TAG=''
DOCKER_REGISTRY='703970026174.dkr.ecr.us-west-2.amazonaws.com'

case "$TRAVIS_BRANCH" in
  "master")
    DOCKER_ENV=production
    DOCKER_TAG=latest
    ;;  
esac

export PATH=$PATH:$HOME/.local/bin

add-apt-repository -y ppa:eugenesan/ppa
apt-get update
apt-get install jq -y

# install ecs-deploy
curl https://raw.githubusercontent.com/silinternational/ecs-deploy/master/ecs-deploy | \
  sudo tee -a /usr/bin/ecs-deploy
sudo chmod +x /usr/bin/ecs-deploy

pip install --user awscli

eval $(aws ecr get-login --region us-west-2 --no-include-email)
docker build -f ./src/NosCoreBot/dockerfile -t noscorebot:$DOCKER_TAG --no-cache .
docker tag noscorebot:$DOCKER_TAG $DOCKER_REGISTRY/noscorebot:$DOCKER_TAG
docker push $DOCKER_REGISTRY/noscorebot:$DOCKER_TAG

ecs-deploy -c noscorebot-cluster -n noscorebot -i $DOCKER_REGISTRY/noscorebot:latest  -D 1  --max-definitions 1 --force-new-deployment
