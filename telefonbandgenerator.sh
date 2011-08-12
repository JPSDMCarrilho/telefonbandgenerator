#!/bin/bash
#
# STEFAN SCHLESINGER's TELEFON BAND GENERATOR v1
#

# A 22050Hz/mono/MP3 file which we create a long loop from.
MUSIC=loop.mp3

# Loundness factor of the background music.
LOUDNESS=0.3

VERSION=1

say_something_mp3() {
    voice=$1 ; text=$2 ;  out=$3 ; out_mp3=$(echo $out|sed 's/\.aiff/_step1\.mp3/')
    echo -n "$text - vice: $voice  "
    say --progress -v $voice -f $text -o $out
    lame -S -h -m m -b 64 $out $out_mp3
}

generate_main_loop() {
    echo "Generating main loop"
    sox -c 1 $MUSIC $MUSIC $MUSIC $MUSIC $MUSIC out/__music_loud.mp3
    sox -v $LOUDNESS out/__music_loud.mp3 out/__music.mp3
    rm out/__music_loud.mp3
}



echo ; echo "#################### STEFAN SCHLESINGER's TELEFONBAND GENERATOR v${VERSION}"

#
# Preflight checks, before we roll.
# 
[[ ! -d "out" ]]     &&  mkdir out
[[ ! -f "$MUSIC" ]]  &&  echo "ERROR: Cannot find the music file, please create it in ${MUSIC}." && exit 5
[[ ! -d "text" ]]    &&  echo "ERROR: No texts where found, please create them in the text directory." && exit 5

[[ ! -x `which say` ]]  && echo "ERROR: Cannot find TTS Engine (say)" && exit 5
[[ ! -x `which lame` ]] && echo "ERROR: Cannot find Lame." && exit 5
[[ ! -x `which sox` ]]  && echo "ERROR: Cannot find SOX." && exit 5

#
# STEP 1
#
echo ; echo "#################### Step 1 - Create MP3 from Texts."

for file in `ls text/*.txt|grep -v loop` ; do
    lang=$(echo ${file} | awk -F/ '{print $2}'| awk -F- '{print $1}')
    part=$(echo ${file} | awk -F/ '{print $2}'| awk -F- '{print $2}' |awk -F. '{print $1}')
    case "${lang}" in
        "de")
            voice="Steffi"
            ;;
        "en")
            voice="Samantha"
            ;;
        "fr")
            voice="Virginie"
            ;;
        *)
            echo "Warning: Cannot figure out voice for language ${lang} ignoring."
            continue
            ;;
    esac

    say_something_mp3 $voice $file out/$lang-$part.aiff
done

#
# STEP 2
#
echo ; echo "#################### Step 2 -- Adding the music"

generate_main_loop

for file in `ls out/*_step1.mp3` ; do
    part=$(echo ${file} | awk -F/ '{print $2}'| awk -F- '{print $1}')
    lang=$(echo ${file} | awk -F/ '{print $2}'| awk -F- '{print $2}' |awk -F. '{print $1}' |awk -F_ '{print $1}')
    speech_duration=$(sox --i $file |grep Duration|awk -F': ' '{print $2}'|awk -F'= ' '{print $1}')

    echo "$part-${lang}: Generate music loop."
    # Create the music loop
    sox out/__music.mp3 out/$part-${lang}_music.mp3 trim 0 $speech_duration

    # Merge the music loop with the speech file
    echo "$part-${lang}: Merge speech with music into one file."
    sox -m out/$part-${lang}_step1.mp3 out/$part-${lang}_music.mp3 out/$part-${lang}_step2.mp3
done

#
# STEP 3
#
echo ; echo "#################### Step 3 -- Cleaning up"
rm out/*.aiff
rm out/__*.mp3
rm out/*step1*.mp3
rm out/*music*.mp3

echo "#################### DONE"
