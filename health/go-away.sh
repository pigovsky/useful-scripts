sleep 2
NOW=$(date +"%Y-%m-%dT%H-%M-%S")
fswebcam "1_$NOW.jpg"
./volume.sh 1.3
spd-say "Yeva i Roman, widiydit wid ekranu! Zaraz wyklyuchusya!"
sleep 5
./volume.sh .5
