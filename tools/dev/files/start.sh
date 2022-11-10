#! /bin/bash

echo "LOTUS | Starting..."
sh ./start_lotus.sh
echo "LOTUS | Started!"

sh ./mock_accounts.sh


echo "LOTUS | Finished setting up"