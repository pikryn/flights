cp $PWD/flights.service /etc/systemd/system/flights.service
cp $PWD/flights.timer /etc/systemd/system/flights.timer
systemctl daemon-reload
systemctl restart flights.timer
