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

remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/portfolio\" ; }; cleanup ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/portfolio\"; log 'Unpacking workspace...' ; tar -C \"\$HOME/portfolio\" -xjv ; log 'Launching docker-compose...' ; cp \"\$HOME/portfolio-cfg/env-vars.txt\" \"\$HOME/portfolio/\" ; cp \"\$HOME/portfolio-cfg/certificate.crt\" \"\$HOME/portfolio/nginx/\" ; cp \"\$HOME/portfolio-cfg/private.key\" \"\$HOME/portfolio/nginx/\" ; cd \"\$HOME/portfolio/\" ; docker compose --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" pull ; docker compose --env-file env-vars.txt -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --remove-orphans --build"

ssh-add <(echo "$SSH_PRIVATE_KEY")

echo ">> [local] Connecting to remote host."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SSH_USER@$SSH_HOST" -p "$SSH_PORT" \
  "$remote_command" \
  < /tmp/workspace.tar.bz2
