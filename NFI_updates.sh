#!/bin/bash

source config.conf

# Go to NFI directory
cd $NFI_PATH
# Fetch latest tags
git fetch --tags
# Get tags names
latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
current_tag=$(git describe --tags)

# Create a new branch with the latest tag name and copy the new version of the strategy
if [ "$latest_tag" != "$current_tag" ]; then

        # Checkout to latest tag and update the NFI in Freqtrade folder
        git checkout tags/$latest_tag -b $latest_tag || git checkout $latest_tag 
        cp -f $NFI_PATH*.py $STRAT_PATH

        # Get tag to which the latest tag is pointing
        latest_tag_commit=$(git rev-list -n 1 tags/${latest_tag})
		
		# Compose the main message send by the bot
        curl -s --data "text=NFI is updated to tag: *${latest_tag}* . Please wait for reload..." \
                --data "parse_mode=markdown" \
                --data "chat_id=$TG_CHAT_ID" \
                "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"


        cd $FT_PATH
        docker stop $(docker ps -q) || true && pkill -f tmux || true && tmux new-session -d -s freqtrade && tmux send-keys "docker-compose -p ${FT_FOLDER@Q} run --rm ${FT_FOLDER@Q}" 'C-m' && tmux detach -s freqtrade

        curl -s --data "text=NFI reload has been completed!" \
                --data "parse_mode=markdown" \
                --data "chat_id=$TG_CHAT_ID" \
                "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"
fi
