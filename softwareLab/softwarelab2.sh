#!/bin/bash
#This script can be used to fetch data from the weather API servers to see if
#should be carrying Umbrella while going to the class or not. I am planning to
#run it as a cron job scheduled every morning to send me reminders. I am using
#telegram bot api for sending the messages to myself and weatherAPI for checking
#the weather. As a good practice, I have exported the API keys in the bashrc file
#I have uploaded the working demo of this script on the link below.

filename=/tmp/$(date -Ihours).json #Name of the temporary file to store the output of the weather api data.
weatherAPI=$weatherAPI
botAPI=$botAPI
chatId=858000187                                                                                                                                 #This is unique to the subscriber of the bot. If needed, we can store a list of chatIDs and iterate to send them all the weather update.
status=$(curl -s -w "%{http_code}" "https://api.weatherapi.com/v1/forecast.json?key=$weatherAPI&q=Mumbai&days=1&aqi=no&alerts=yes" -o $filename) # To check if the curl request was successful.
if [ $status -eq 200 ]; then
    max_temp=$(cat $filename | jq .forecast.forecastday[0].day.maxtemp_c)
    min_temp=$(cat $filename | jq .forecast.forecastday[0].day.mintemp_c)
    avghumidity=$(cat $filename | jq .forecast.forecastday[0].day.avghumidity)
    dailywillitrain=$(cat $filename | jq .forecast.forecastday[0].day.daily_will_it_rain)
    dailychanceofrain=$(cat $filename | jq .forecast.forecastday[0].day.daily_chance_of_rain)
    conditionText=$(cat $filename | jq .forecast.forecastday[0].day.condition.text)
    conditionimage="https:"
    conditionimage+=$(cat $filename | jq .forecast.forecastday[0].day.condition.icon)
    if [ $dailywillitrain -eq 1 ]; then
        message="RAINFALL ALERT!"
    fi
    message+=$'\nMaximum Temperature: '"$max_temp" #crafting the message with the necessary details.
    message+=$'\nMinimum Temperature: '"$min_temp"
    message+=$'\nAverage Humidity: '"$avghumidity"
    message+=$'\nCan it Rain: '"$dailywillitrain"
    message+=$'\nChances of Rain: '"$dailychanceofrain"
    message+=$'\nForecast: '"$conditionText"
    message+=$'\nIcon of the day: '"$conditionimage"

else
    message="Something is wrong with the API or connectivity. Please check!"
fi
rm $filename # removing the filename as soon as the message generation is over.
curl -s -X POST "https://api.telegram.org/bot$botAPI/sendMessage" \
    --data-urlencode "text=$message" \
    -d chat_id="$chatId" >/dev/null 2>&1
