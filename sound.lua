local args = {...}
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()

-- Songs:
-- "data/music/test.dfpwm"  from mp3 (more noisy high ends)
-- "data/music/test2.dfpwm" from wav (more noisy low ends)
-- "lowpass.dfpwm" attempt to generate audio

local sound = "data/music/booze.dfpwm"
local volume = 100

if args[1] ~= nil then
    sound = args[1]..".dfpwm"
end
if args[2] ~= nil then
    volume = args[2]
end


local wholeSong = {}

for chunk in io.lines(sound, 16 * 1024) do
    local buffer = decoder(chunk)  
    while not speaker.playAudio(buffer, volume*0.01) do
        os.pullEvent("speaker_audio_empty")
    end
end
