#! /bin/bash

echo "LOTUS | Starting..."
sh ./start_lotus.sh
echo "LOTUS | Started!"

echo "Starting mock accounts..."
sh ./mock_accounts.sh
echo "Done executing mock accounts"


echo "LOTUS | Finished setting up"