#! /bin/bash

echo "Lotus | Initializing"
sh ./start_lotus.sh
echo "Lotus | Initialized!"

if [[ -z "${MOCK_ACCOUNTS}" ]]; then
  echo "Mock accounts | Starting mock accounts script"
  sh ./mock_accounts.sh
  echo "Mock accounts | Done!"

echo "Lotus | Set up completed"
