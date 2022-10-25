#! /bin/bash

echo "LOTUS | Starting..."
sh ./start_lotus.sh
echo "LOTUS | Started!"

if [[ -z "${MOCK_ACCOUNTS}" ]]; then
  echo "MOCK ACCOUNTS | Starting..."
  sh ./mock_accounts.sh
  echo "MOCK ACCOUNTS | Finished!"
fi

echo "LOTUS | Finished setting up"