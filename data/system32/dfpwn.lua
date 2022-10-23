local args = {...}
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()

print("Starting")

-- Songs:
-- "data/music/test.dfpwm"  from mp3 (more noisy high ends)
-- "data/music/test2.dfpwm" from wav (more noisy low ends)
-- "lowpass.dfpwm" attempt to generate audio

local sound = "data/music/test.dfpwm"
if args[1] ~= nil then
    sound = args[1]
end

for chunk in io.lines(sound, 16 * 1024) do
    local buffer = decoder(chunk)
    
    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end
print("Finished")
