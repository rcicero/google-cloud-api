#!/bin/bash

#Image Path
IMAGE_NAME=foto.png

#Words
declare -a words=();

takePicture(){
	#Web Cam
	fswebcam --jpeg 85 $IMAGE_NAME
	BASE64_IMAGE=$( base64 $IMAGE_NAME )
}

callGoogleApi(){

	#API KEY {Entrar no Google Cloud Console e gerar uma Credencial de Chave de API}
	KEY={API GOOGLE}

	#Montando a request -> parametros com base na doc Google Api Vision
	REQUEST='{"requests":[{"image": {"content":"'$BASE64_IMAGE'"},"features":[{"type":"LABEL_DETECTION","maxResults":10}]}]}'

	#Call GOOGLE
	RESPONSE=$(echo ${REQUEST} | curl -k -s -H "Content-Type: application/json" https://vision.googleapis.com/v1/images:annotate?key=$KEY --data-binary @-)
}

getWordsInformation(){
	local -a wordList=()
	ITENS=$(echo $RESPONSE | python -c "import json,sys;obj=json.load(sys.stdin);print len(obj['responses'][0]['labelAnnotations']);")
	for (( count=0; count < $ITENS; ++count )); do
		wordList[$count]=$(echo $RESPONSE | python -c "import json,sys;obj=json.load(sys.stdin);print obj['responses'][0]['labelAnnotations']["$count"]['description'];")
	done
	echo ${wordList[*]}
}

getWordsAndScoreInformation(){
	local -a wordList=()
	ITENS=$(echo $RESPONSE | python -c "import json,sys;obj=json.load(sys.stdin);print len(obj['responses'][0]['labelAnnotations']);")
	for (( count=0; count < $ITENS; ++count )); do
		word=$(echo $RESPONSE | python -c "import json,sys;obj=json.load(sys.stdin);print obj['responses'][0]['labelAnnotations']["$count"]['description'];")
		wordList[$count]=$word" "$(echo $RESPONSE | python -c "import json,sys;obj=json.load(sys.stdin);print obj['responses'][0]['labelAnnotations']["$count"]['score'];")
	done
	echo ${wordList[*]}
}

learn(){

	local menuOption="s";
	echo -n "Qual o nome do que vamos aprender? "
	read learnTitle
	# TODO validar se foi digitado alguma coisa
	echo "Legal, vamos aprender sobre $learnTitle"
	sleep 2
	echo "Vou preparar algumas coisas..."

	# TODO validar se o arquivo ja existe
	#if [[ find -name learning/right/$learnTitle ]]: then
	#	echo "existe"
	#else
	#	echo "nao existe"
	#fi
	> learning/right/$learnTitle
	> learning/wrong/$learnTitle
	sleep 2
	echo "Tudo preparado! Podemos começar."
	sleep 2
	echo "Vou tirar uma foto e você me diz se é ou não o que espera"
	sleep 4
	
	while [ $menuOption = "s" ]; do

		takePicture
		callGoogleApi
		words=$(getWordsAndScoreInformation)

		echo "Nesta foto eu encontrei -> ${words[*]}"
		echo -n "Está correto (s/n)? "
		read option

		if [ $option = "s" ]; then
			for item in $words; do
				echo $item >> learning/right/$learnTitle
			done
		elif [ $option = "n" ] ; then
			for item in $words; do
				echo $item >> learning/wrong/$learnTitle
			done
		else
			echo "Algo de errado ocorreu"
		fi


		echo -n "Deseja continuar (s/n)? "
		read menuOption
	done
	sleep 2
	echo "Ok. Vou processar os dados e finalizar o treinamento"
	sleep 3

}

##### Main
if [ "$1" = 'learn' ] ; then
	learn
elif [ "$1" = "analyze" ] ; then
	takePicture
	callGoogleApi
	words=$(getWordsInformation)
	echo ${words[*]}
else
	echo "Comando não encontrado!"
fi
