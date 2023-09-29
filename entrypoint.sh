#!/usb/bin/env bash
set -e

log() {
  echo ">> [local]" $@
}

cleanup() {
  set +e
  log "Killing ssh agent."
  ssh-agent -k
  log "Removing workspace archive."
  rm -f /tmp/workspace.tar.bz2
}


log "Packing workspace into archive to transfer onto remote machine."
tar cjvf /tmp/workspace.tar.bz2 --exclude .git --exclude vendor .

log "Launching ssh agent."
eval `ssh-agent -s`

<<<<<<< HEAD
remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/microtasker\" ; }; cleanup ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/microtasker\"; log 'Unpacking workspace...' ; tar -C \"\$HOME/microtasker\" -xjv ; log 'Launching docker-compose...' ; cd \"\$HOME/microtasker\" ; cp \"\$HOME/microtasker-cfg/env-vars.txt\" ./ ; docker compose --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" pull ; docker compose --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --remove-orphans --build"
=======
remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/microtasker\" ; }; cleanup ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/microtasker\"; log 'Unpacking workspace...' ; tar -C \"\$HOME/microtasker\" -xjv ; log 'Launching docker-compose...' ; cd \"\$HOME/microtasker\" ; cp \"\$HOME/microtasker-cfg/env-vars.txt\" ./ ; docker compose --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" pull ; docker compose --sysctl net.ipv6.conf.all.disable_ipv6=1 --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --remove-orphans --build"
>>>>>>> de8a6a68994e6715f74a8c5d938e1f39a6b3ff1f
if $USE_DOCKER_STACK ; then
  remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/microtasker\" ; } ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/microtasker/$DOCKER_COMPOSE_PREFIX\" ; trap cleanup EXIT ; log 'Unpacking workspace...' ; tar -C \"\$HOME/microtasker/$DOCKER_COMPOSE_PREFIX\" -xjv ; log 'Launching docker stack deploy...' ; cd \"\$HOME/microtasker/$DOCKER_COMPOSE_PREFIX\" ; docker stack deploy -c \"$DOCKER_COMPOSE_FILENAME\" --prune \"$DOCKER_COMPOSE_PREFIX\""
fi
if $DOCKER_COMPOSE_DOWN ; then
  remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/microtasker\" ; } ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/microtasker\" ; trap cleanup EXIT ; log 'Unpacking workspace...' ; tar -C \"\$HOME/microtasker\" -xjv ; log 'Launching docker-compose...' ; cd \"\$HOME/microtasker\" ; cp \"\$HOME/microtasker-cfg/env-vars.txt\" ./ ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" down"
fi

ssh-add <(echo "$SSH_PRIVATE_KEY")

echo ">> [local] Connecting to remote host."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SSH_USER@$SSH_HOST" -p "$SSH_PORT" \
  "$remote_command" \
  < /tmp/workspace.tar.bz2
