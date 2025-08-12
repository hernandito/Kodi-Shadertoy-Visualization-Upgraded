import xbmc
import xbmcaddon
import xbmcvfs
import os
import random
import time
import xml.etree.ElementTree as ET

ADDON = xbmcaddon.Addon()
ADDON_ID = ADDON.getAddonInfo('id') # Will be "service.shadertoy.cycler"
SHADER_PATH = xbmcvfs.translatePath('special://home/addons/screensaver.shadertoy/resources/shaders/')
SETTINGS_PATH = "/storage/.kodi/userdata/addon_data/screensaver.shadertoy/settings.xml"
TEXTURE_PATH = xbmcvfs.translatePath('special://home/addons/screensaver.shadertoy/resources/')
CYCLE_INTERVAL = 60 # 10 seconds as set
LOG_INTERVAL = 52    # Log every 30 seconds
SetToTester = 1      # Set to 1 to use only testershader.frag.glsl, 0 to cycle through FIXED_SHADERS


##############################################
#   VERIFY SHADERS ARE CYCLING PROPERLY
##############################################
#
#   In Terminal:   cat /storage/.kodi/temp/kodi.log | grep "Shaders in batch" > listme.txt
#   Open file listme in Notepad++
#       Go to Search > Replace: in find type:  ^.*(?=Current\s) - Replace with (leave blank). 
#           This will strip the timestamps, etc.
#       Go to Search > Replace: in find type:  "Current shader: " - Replace with (leave blank).  
#       Go to Search > Replace: in find type:  "Shaders in batch: " - Replace with "File Number: " 
#       Go to Edit > Line Operations > and click on "Remove Consecutive Duplicate Lines"
#       Delete repeat cycle lines, and lines not relevant to file list.
#
#   In Grok or ChatGPT eneter the below:
#       Please find file list below. In the below list, each line contains a *.frag.glsl file name. The file name is followed by a File Number. Please look at file names and advise if there are more than one unique file name on the list. Please note that the File Number should be unique as well and should count down in the number sequence. Please ignore if the same file name and unique FILE NUMBER repeat one after the other. There is no need to itemize line by line in your response. Please only highlight if any file names repeat, or it the File Numbers are not in sequential order from high to low. 
#
#   - Paste the file list from Notepad++
##############################################

#* Hernando - Notes on Customizing
#    after any change, Kodi must be restarted. use this to re-start:
#        systemctl restart kodi
# to check kodi log to diagnose shaders:     cat /storage/.kodi/temp/kodi.log

#
#    Texture extraction command in Libreelec:
#      sh gettexture.sh https://www.shadertoy.com/view/ldl3W8
#
#    Manual Browser Method (If Script Above Fails)
#
#        Open https://www.shadertoy.com/view/ldl3W8 in Firefox.
#        Open Developer Tools (Ctrl+Shift+I), go to the Network tab, and enable persistent logs (gear icon > “Enable persistent logs”).
#        Reload the page (Ctrl+F5).
#        Filter by Images and look for a 256x256 PNG file loaded from a path like https://www.shadertoy.com/media/a/.... This is the tex03 texture.
#        Right-click the request, copy the URL, and download the image.
#
#
#
#
#        Test commands:            tail -n 10000 /storage/.kodi/temp/kodi.log | grep "service.shadertoy.cycler"
#                                  tail -n 10000 /storage/.kodi/temp/kodi.log | grep "Running, current"
#                                  tail -n 10000 /storage/.kodi/temp/kodi.log | grep "not found"
#
#                                   tail -n 10000 /storage/.kodi/temp/kodi.log | grep "Refreshed screensaver"          
#          This will show only filesnames.           tail -n 6250 /storage/.kodi/temp/kodi.log | grep "Refreshed screensaver for " | awk -F'for ' '{print $2}'
#          This will show a numbered list:            tail -n 6250 /storage/.kodi/temp/kodi.log | grep "Refreshed screensaver for " | awk -F'for ' '{print $2}' | awk '{printf "%d %s\n", NR, $0}'

#          This one checks for duplicates:          
#          (will return blank if no duplicates found).     tail -n 6250 /storage/.kodi/temp/kodi.log | grep "Refreshed screensaver for " | awk -F'for ' '{print $2}' | awk '{printf "%d %s\n", NR, $0}' | cut -d' ' -f2- | sort | uniq -d



# Fixed list of shaders from the Shadertoy addon (excluding main*.* files)
FIXED_SHADERS = [

#    Shaders that require a better specced PC
#    Disable for the Intel N100 PC
#    Enable for Intel NUC
#    Commented out due to performance issues on lower-spec machines
#    '00fractal1.frag.glsl',
#    '00fractal2.frag.glsl',
#    '00fractal3.frag.glsl',
#    'bubblehell.frag.glsl',
#    'windyplanes.frag.glsl',
#    'jupitershapes.frag.glsl',
#    'windyplanes.frag.glsl',
#    'papercity.frag.glsl',

#    End of special shaders  tex04rain

    '00fractal1.frag.glsl',
    '00fractal2.frag.glsl',
    '00fractal3.frag.glsl',
    '0gfire.frag.glsl',
    '3dspheres.frag.glsl',
    '3dstudio.frag.glsl',
    '4dapollian.frag.glsl',
    '50ssitcom.frag.glsl',
    '60stvset.frag.glsl',
    'abovetheclouds.frag.glsl',
    'abstractcells.frag.glsl',
    'acidcheese.frag.glsl',
    'acidwallpaper.frag.glsl',
    'acrylicubes.frag.glsl',
    'acvent.frag.glsl',
    'alienquote.frag.glsl',
    'alientech.frag.glsl',
    'alienwaterworld.frag.glsl',
    'alveoli.frag.glsl',
    'amoebas.frag.glsl',
    'ancienttemple.frag.glsl',
    'anemone.frag.glsl',
    'anewflame.frag.glsl',
    'angrycloud.frag.glsl',
    'anothertanh.frag.glsl',
    'anothertunnel.frag.glsl',
    'apollonianstructure.frag.glsl',
    'apollospiral.frag.glsl',
    'approachingheaven.frag.glsl',
    'arabesque.frag.glsl',
    'artdeco.frag.glsl',
    'artichoke.frag.glsl',
    'ashfall.frag.glsl',
    'atom.frag.glsl',
    'atomicclock.frag.glsl',
    'ball.frag.glsl',
    'ballfarm.frag.glsl',
    'ballinahole.frag.glsl',
    'balloffire.frag.glsl',
    'basilica.frag.glsl',
    'bathiscaph.frag.glsl',
    'beachrain.frag.glsl',
    'beatbox.frag.glsl',
    'beatingheart.frag.glsl',
    'biblical.frag.glsl',
    'bicycle.frag.glsl',
    'biowall.frag.glsl',
    'blackholesun.frag.glsl',
    'blacktliquidcube.frag.glsl',
    'blacktar.frag.glsl',
    'blade.frag.glsl',
    'blade2049.frag.glsl',
    'bleepyblocks.frag.glsl',
    'blizzard.frag.glsl',
    'blobs.frag.glsl',
    'bloodcells.frag.glsl',
    'bloodmilk.frag.glsl',
    'bloodyriver.frag.glsl',
    'bloomingflower.frag.glsl',
    'bluefire.frag.glsl',
    'bluescaffold.frag.glsl',
    'bocchi.frag.glsl',
    'bonemandel.frag.glsl',
    'bonestructure.frag.glsl',
    'bonestructure2.frag.glsl',
    'boneytunnel.frag.glsl',
    'bouncingballs.frag.glsl',
    'braidedsphere.frag.glsl',
    'breathingfractal.frag.glsl',
    'britneyspaceship.frag.glsl',
    'brownclouds.frag.glsl',
    'brutalism.frag.glsl',
    'brutalismsliced.frag.glsl',
    'bubblecolors.frag.glsl',
    'bubblefloat.frag.glsl',
    'bubblehell.frag.glsl',
    'burningbush.frag.glsl',
    'camofur.frag.glsl',
    'campfire.frag.glsl',
    'canyon.frag.glsl',
    'cartography.frag.glsl',
    'caverocks.frag.glsl',
    'cellnucleus.frag.glsl',
    'cellular.frag.glsl',
    'chains.frag.glsl',
    'chandelier.frag.glsl',
    'checkeredflag.frag.glsl',
    'chrome.frag.glsl',
    'circuitcity.frag.glsl',
    'clearlyabug.frag.glsl',
    'closeencounters.frag.glsl',
    'cloudframe.frag.glsl',
    'clouds.frag.glsl',
    'cloudycrystal.frag.glsl',
    'colorfullballoons.frag.glsl',
    'conciousstream.frag.glsl',
    'constellations.frag.glsl',
    'constellations2.frag.glsl',
    'constellationsinverted.frag.glsl',
    'coralcave.frag.glsl',
    'coralreef.frag.glsl',
    'corona.frag.glsl',
    'creamywood.frag.glsl',
    'crossbutton.frag.glsl',
    'crtwobblycube.frag.glsl',
    'crudeoil.frag.glsl',
    'crystalgarden.frag.glsl',
    'crystalskull.frag.glsl',
    'cubedizzy.frag.glsl',
    'cubelights.frag.glsl',
    'cubism.frag.glsl',
    'culebra.frag.glsl',
    'dandelion.frag.glsl',
    'datawarehouse.frag.glsl',
    'demonseeman.frag.glsl',
    'destroyedborg.frag.glsl',
    'digitalboard.frag.glsl',
    'digitvortex.frag.glsl',
    'disarmbomb.frag.glsl',
    'discswallpaper.frag.glsl',
    'distantsun.frag.glsl',
    'drawerwall.frag.glsl',
    'drawingbezier.frag.glsl',
    'dunes.frag.glsl',
    'dustgravity.frag.glsl',
    'dvdretro.frag.glsl',
    'dvdretro-nonoise.frag.glsl',
    'emerging.frag.glsl',
    'ether.frag.glsl',
    'eventhorizon.frag.glsl',
    'facade.frag.glsl',
    'fantasticvoyage.frag.glsl',
    'favela.frag.glsl',
    'fibonacisphere.frag.glsl',
    'fingerprint.frag.glsl',
    'fire.frag.glsl',
    'firebutton.frag.glsl',
    'fireghost.frag.glsl',
    'firewall.frag.glsl',
    'fishbones.frag.glsl',
    'flashcards.frag.glsl',
    'flamelighter.frag.glsl',
    'flatbelts.frag.glsl',
    'floralfractal.frag.glsl',
    'flowingpaint.frag.glsl',
    'foreverever.frag.glsl',
    'foreverever2.frag.glsl',
    'fractalcubesteps.frag.glsl',
    'fractalland.frag.glsl',
    'fractalpiano.frag.glsl',
    'fractaltiling.frag.glsl',
    'fur.frag.glsl',
    'gears.frag.glsl',
    'generators.frag.glsl',
    'giraffefur.frag.glsl',
    'gitrack.frag.glsl',
    'glasspentahedron.frag.glsl',
    'glassstudy.frag.glsl',
    'glowbubble.frag.glsl',
    'gnarlytree.frag.glsl',
    'goldenapollonian.frag.glsl',
    'goldensection.frag.glsl',
    'goldrain.frag.glsl',
    'goldspiral.frag.glsl',
    'goldtears.frag.glsl',
    'golfballs.frag.glsl',
    'gooeyeraser.frag.glsl',
    'gradientcircles.frag.glsl',
    'greeneye.frag.glsl',
    'greenlattice.frag.glsl',
    'greenslime.frag.glsl',
    'guildnavigator.frag.glsl',
    'hallofmirrors.frag.glsl',
    'halftonecell.frag.glsl',
    'halftonemetaballs.frag.glsl',
    'handsketch.frag.glsl',
    'hangingart.frag.glsl',
    'happycloud.frag.glsl',
    'hashtag.frag.glsl',
    'hatchery.frag.glsl',
    'heavenly.frag.glsl',
    'hexagonblocks.frag.glsl',
    'hexapolygon.frag.glsl',
    'hexapolyhedron.frag.glsl',
    'hilbertcube.frag.glsl',
    'hippybee.frag.glsl',
    'hotrocks.frag.glsl',
    'househarkonnen.frag.glsl',
    'hyperspace2.frag.glsl',
    'iguanaeye.frag.glsl',
    'illuminatedsphere.frag.glsl',
    'inferno.frag.glsl',
    'infinitecubezoom.frag.glsl',
    'infinitedoorway.frag.glsl',
    'infinitefall.frag.glsl',
    'infinitycube.frag.glsl',
    'inthetornado.frag.glsl',
    'intothefeather.frag.glsl',
    'intothehive.frag.glsl',
    'intothemint.frag.glsl',
    'jellysomething.frag.glsl',
    'jetsons.frag.glsl',
    'juliaprojection.frag.glsl',
    'juliatrap.frag.glsl',
    'kaleidoscope.frag.glsl',
    'kaleidoscope-inv.frag.glsl',
    'kite.frag.glsl',
    'kodimac.frag.glsl',
    'latticemaze.frag.glsl',
    'lavalamp.frag.glsl',
    'lavalamp2.frag.glsl',
    'leather.frag.glsl',
    'legolike.frag.glsl',
    'likecorian.frag.glsl',
    'liketetris.frag.glsl',
    'liquidspectrum.frag.glsl',
    'liquidspectrum-mono.frag.glsl',
    'liquidtin.frag.glsl',
    'lizardskin.frag.glsl',
    'lostsoldier.frag.glsl',
    'magneticindicators.frag.glsl',
    'maibuterflai.frag.glsl',
    'mandala.frag.glsl',
    'mandala2.frag.glsl',
    'mandel.frag.glsl',
    'mandelbrot.frag.glsl',
    'mandelbrotcarvings.frag.glsl',
    'mandelsnow.frag.glsl',
    'mapamundi.frag.glsl',
    'marchingdie.frag.glsl',
    'marsflythru.frag.glsl',
    'martiandusk.frag.glsl',
    'meatballs.frag.glsl',
    'mellowvoronoi.frag.glsl',
    'mengerdrift.frag.glsl',
    'mengermass.frag.glsl',
    'metaballspiral.frag.glsl', 
    'metalblocks.frag.glsl',
    'microtorus.frag.glsl',
    'microwaves.frag.glsl',
    'milkdrop.frag.glsl',
    'mobiuseggs.frag.glsl',
    'monastery.frag.glsl',
    'morphingmengersponge.frag.glsl',
    'mosaic.frag.glsl',
    'mosaictiles.frag.glsl',
    'mountainlake.frag.glsl',
    'mountainsunrise.frag.glsl',
    'mrbert.frag.glsl',
    'mrbouncy.frag.glsl',
    'murakami.frag.glsl',
    'murkywater.frag.glsl',
    'muscletissue.frag.glsl',
    'mushroomlights.frag.glsl',
    'myphobia.frag.glsl',
    'nebulaflight.frag.glsl',
    'nebulaflight2.frag.glsl',
    'nebulosa.frag.glsl',
    'neonknights.frag.glsl',
    'neonmoon.frag.glsl',
    'nestedspheres.frag.glsl',
    'newenergy.frag.glsl',
    'nightdive.frag.glsl',
    'nightsea.frag.glsl',
    'nixieclock.frag.glsl',
    'noiseanimlava.frag.glsl',
    'nubela.frag.glsl',
    'oceanwaves.frag.glsl',
    'octopus.frag.glsl',
    'octopusblood.frag.glsl',
    'octopuseye.frag.glsl',
    'officehell.frag.glsl',
    'orangesky.frag.glsl',
    'origamikaleidoscope.frag.glsl',
    'origamishift.frag.glsl',
    'outerlimits.frag.glsl',
    'paintchips.frag.glsl',
    'painterlytunnel.frag.glsl',
    'paislymilk.frag.glsl',
    'paistropical.frag.glsl',
    'palettes.frag.glsl',
    'pantonechips.frag.glsl',
    'papagallo.frag.glsl',
    'papercity.frag.glsl',
    'paperairplanes.frag.glsl',
    'paperkaleidoscope.frag.glsl',
    'paperlantern.frag.glsl',
    'paperwaterfall.frag.glsl',
    'parsley.frag.glsl',
    'partlycloudy.frag.glsl',
    'pcb.frag.glsl',
    'permutations.frag.glsl',
    'phosphor3.frag.glsl',
    'picassoblocks.frag.glsl',
    'pinkblocks.frag.glsl',
    'pixiecubes.frag.glsl',
    'planetarium.frag.glsl',
    'planeteclipse.frag.glsl',
    'planetfall.frag.glsl',
    'plankton.frag.glsl',
    'plasmaspider.frag.glsl',
    'plutoniancells.frag.glsl',
    'polyweave.frag.glsl',
    'popart.frag.glsl',
    'protoplasm.frag.glsl',
    'pseudoletters.frag.glsl',
    'puffy.frag.glsl',
    'pyramidpattern.frag.glsl',
    'quadtruchet.frag.glsl',
    'radar.frag.glsl',
    'radarr.frag.glsl',
    'rainyheadlights.frag.glsl',
    'rbc.frag.glsl',
    'redgasgiant.frag.glsl',
    'redjulia.frag.glsl',
    'redvelvet.frag.glsl',
    'reflectivehextiles.frag.glsl',
    'rendering.frag.glsl',
    'ribbons.frag.glsl',
    'rings.frag.glsl',
    'ringscube.frag.glsl',
    'ringworms.frag.glsl',
    'ringworms2.frag.glsl',
    'riverrocks.frag.glsl',
    'rocketgantry.frag.glsl',
    'rolling.frag.glsl',
    'rollinghills.frag.glsl',
    'ropes.frag.glsl',
    'rorshak.frag.glsl',
    'rorshak2.frag.glsl',
    'rothko.frag.glsl',
    'runner.frag.glsl',
    'sandstonecity.frag.glsl',
    'salgarnight.frag.glsl',
    'satphoto.frag.glsl',
    'sea.frag.glsl',
    'seasky.frag.glsl',
    'seaurchin.frag.glsl',
    'seismograph.frag.glsl',
    'sepiasky.frag.glsl',
    'shootingstars.frag.glsl',
    'silexarst.frag.glsl',
    'singularity.frag.glsl',
    'singularity2.frag.glsl',
    'skulltv.frag.glsl',
    'smiley.frag.glsl',
    'smokecube.frag.glsl',
    'smokeonthewater.frag.glsl',
    'snowfall.frag.glsl',
    'solitaria.frag.glsl',
    'sonarr.frag.glsl',
    'soylentgreen.frag.glsl',
    'spacecity.frag.glsl',
    'spacerace.frag.glsl',
    'spaceship.frag.glsl',
    'spaceshipdusk.frag.glsl',
    'spaceshipv2.frag.glsl',
    'spacesonar.frag.glsl',
    'speakers.frag.glsl',
    'speakerwall.frag.glsl',
    'spectrumzoom.frag.glsl',
    'spheregears.frag.glsl',
    'spherelights.frag.glsl',
    'spherrain.frag.glsl',
    'spiralstaircases.frag.glsl',
    'spongetunnel.frag.glsl',
    'stylizedsmoke.frag.glsl',
    'succulent.frag.glsl',
    'sugardrops.frag.glsl',
    'summitday.frag.glsl',
    'sunflower.frag.glsl',
    'sunset.frag.glsl',
    'suntiles.frag.glsl',
    'swisscheese.frag.glsl',
    'tendriltunnel.frag.glsl',
    'tentacles.frag.glsl',
    'terracedhills.frag.glsl',
    'textdecode.frag.glsl',
    'textdecode2.frag.glsl',
    'textdecode3.frag.glsl',
    'theabyss.frag.glsl',
    'theborg.frag.glsl',
    'theborg2.frag.glsl',
    'theshining.frag.glsl',
    'thetwilight.frag.glsl',
    'tiedye.frag.glsl',
    'tileexperiment.frag.glsl',
    'time.frag.glsl',
    'timetunnel.frag.glsl',
    'tinybubbles.frag.glsl',
    'tool.frag.glsl',
    'tool2.frag.glsl',
    'toonbubbles.frag.glsl',
    'toruspipes.frag.glsl',
    'torussketch.frag.glsl',
    'trainview.frag.glsl',
    'trainviewnight.frag.glsl',
    'tribalknot.frag.glsl',
    'trippinbee.frag.glsl',
    'troncraft.frag.glsl',
    'truchetcell.frag.glsl',
    'truchetfield.frag.glsl',
    'tunnelandthelight.frag.glsl',
    'tunnellight.frag.glsl',
    'tunnellightclouds.frag.glsl',
    'tweeningwidget.frag.glsl',
    'twinklingtunnel.frag.glsl',
    'twilightzone.frag.glsl',
    'twistedguts.frag.glsl',
    'twistedknot.frag.glsl',
    'twister.frag.glsl',
    'twistycubes.frag.glsl',
    'ufo.frag.glsl',
    'uncontrolledspiral.frag.glsl',
    'uncontrolledspiral2.frag.glsl',
    'underice.frag.glsl',
    'undulatingflower.frag.glsl',
    'undulatingflower.frag.glsl',
    'unicornneurons.frag.glsl',
    'venus.frag.glsl',
    'vhsblues.frag.glsl',
    'viralblob.frag.glsl',
    'viralblob-red.frag.glsl',
    'vitals.frag.glsl',
    'volumetricexplosion.frag.glsl',
    'voronoicubes.frag.glsl',
    'voronoid.frag.glsl',
    'walkingcube.frag.glsl',
    'walkingcube2d.frag.glsl',
    'waterdisco.frag.glsl',
    'waveform.frag.glsl',
    'wet.frag.glsl',
    'wetstone.frag.glsl',
    'whirl.frag.glsl',
    'windyplanes.frag.glsl',
    'windysun.frag.glsl',
    'wiremesh.frag.glsl',
    'wiremesh2.frag.glsl',
    'wispytunnel.frag.glsl',
    'witchesbrew.frag.glsl',
    'woodblocks.frag.glsl',
    'wooddonut.frag.glsl',
    'woodmenger.frag.glsl',
    'worleynoisewaters.frag.glsl',
    'xrayslices.frag.glsl',
    'yingyang.frag.glsl',
    'zen.frag.glsl',

    'testershader.frag.glsl'

    # Added new dual-texture shader (replace with actual filename) tex19
    # 'dualtexture.frag.glsl' # Placeholder for the new shader using iChannel0 and iChannel1
]

TESTER_SHADER = 'testershader.frag.glsl' # Set for testing  tex02 tex12 tex03a tex03c tex01 tex03a tex05a tex05 tex10 tex16 tex03 tex09

class ShaderCycler(xbmc.Monitor):
    def __init__(self):
        super().__init__()
        self.current_shader = ''
        self.all_shaders = list(FIXED_SHADERS) # Use a copy of the fixed list as the master
        self.remaining_shaders = [] # Shaders to be cycled through in the current "batch"
        self.is_cycling = False
        self.is_refreshing = False
        self.screensaver_started = False
        self.last_cycle = time.time()
        xbmc.log(f"{ADDON_ID}: Initializing ShaderCycler with {len(self.all_shaders)} shaders potentially available.", xbmc.LOGINFO)
        self.load_shaders() # This method will populate self.all_shaders with valid ones and shuffle

        if self.all_shaders:
            xbmc.log(f"{ADDON_ID}: Shaders loaded, starting cycle in background", xbmc.LOGINFO)

    def load_shaders(self):
        valid_shaders = []
        if SetToTester == 1:
            if xbmcvfs.exists(os.path.join(SHADER_PATH, TESTER_SHADER)):
                valid_shaders.append(TESTER_SHADER)
                xbmc.log(f"{ADDON_ID}: SetToTester enabled, using only {TESTER_SHADER}", xbmc.LOGINFO)
            else:
                xbmc.log(f"{ADDON_ID}: Tester shader {TESTER_SHADER} not found in {SHADER_PATH}", xbmc.LOGERROR)
        else:
            # Iterate through the initially defined FIXED_SHADERS to validate them
            for shader in self.all_shaders: # Check against the original list
                if xbmcvfs.exists(os.path.join(SHADER_PATH, shader)):
                    valid_shaders.append(shader)
                else:
                    xbmc.log(f"{ADDON_ID}: Shader {shader} not found in {SHADER_PATH}, skipping", xbmc.LOGWARNING)

        self.all_shaders = valid_shaders # Update the master list to only include valid shaders
        if not self.all_shaders:
            xbmc.log(f"{ADDON_ID}: No valid shaders found", xbmc.LOGERROR)
        else:
            xbmc.log(f"{ADDON_ID}: Loaded {len(self.all_shaders)} valid shaders", xbmc.LOGINFO)
            # Shuffle the entire list of valid shaders once after loading
            random.shuffle(self.all_shaders)
            # Initialize the remaining_shaders list for the first cycle batch
            self.remaining_shaders = list(self.all_shaders) # Make a copy for the batch

    def update_settings_xml(self, shader):
        try:
            tree = ET.parse(SETTINGS_PATH)
            root = tree.getroot()
            # Update shader settings
            for setting in root.findall('setting'):
                if setting.get('id') == 'shader':
                    setting.text = os.path.join(SHADER_PATH, shader)
                elif setting.get('id') == 'ownshader':
                    setting.text = 'true'
                # Set texture0 (iChannel0) for specific shaders
                elif setting.get('id') == 'texture0':

                    ################################################
                    # MODIFIED SECTION FOR paperlantern.frag.glsl iChannel0
                    if shader == 'paperlantern.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02hr.png') # Correct texture for iChannel0
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)
                    # END MODIFIED SECTION FOR paperlantern.frag.glsl iChannel0


                    ################################################
                    # MODIFIED SECTION FOR drawerwall.frag.glsl iChannel0
                    if shader == 'drawerwall.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02hr.png') # Correct texture for iChannel0
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)
                    # END MODIFIED SECTION FOR paperlantern.frag.glsl iChannel0






                    elif shader == 'paperwaterfall.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex00.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['fur.frag.glsl', 'brutalism.frag.glsl', 'hotrocks.frag.glsl', 'myphobia.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex01.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex01.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['ropes.frag.glsl', 'metalblocks.frag.glsl', 'picassoblocks.frag.glsl', 'brutalismsliced.frag.glsl', 'liquidtin.frag.glsl', 'culebra.frag.glsl', 'marchingdie.frag.glsl', 'fractalcubesteps.frag.glsl', 'spheregears.frag.glsl', 'mengerdrift.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['hexapolygon.frag.glsl', 'brutalismsliced.frag.glsl', 'tweeningwidget.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02hr.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['eventhorizon.frag.glsl', 'mistymountainhop.frag.glsl', 'peace.frag.glsl', 'ballinahole.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex03a.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture tex03a.png not found, falling back to tex03.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['plutoniancells.frag.glsl', 'sunset.frag.glsl', 'conception.frag.glsl', 'troncraft.frag.glsl', 'abovetheclouds.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex03c.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture {texture_path} not found, falling back to tex03.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['hallofmirrors.frag.glsl', 'londoncafe.frag.glsl', 'infinitycube.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex04.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture tex04.png not found, falling back to tex03.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'beachrain.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex04rain.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'speakers.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex05a.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['woodblocks.frag.glsl', 'wiremesh.frag.glsl', 'truchetfield.frag.glsl', 'woodmenger.frag.glsl', 'wooddonut.frag.glsl', 'creamywood.frag.glsl', 'britneyspaceship.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex05.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex05.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader == 'riverrocks.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'pebbles.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'protoplasm.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex06.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['muscletissue.frag.glsl', 'circuitcity.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex07.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex07.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['crystalgarden.frag.glsl', 'volumetricexplosion.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex09.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'windyplanes.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex10.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex11.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'rorshak2.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex11.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex11.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['permutations.frag.glsl', '50ssitcom.frag.glsl', 'trainview.frag.glsl', 'leather.frag.glsl', 'mandelsnow.frag.glsl', 'noiseanimlava.frag.glsl', 'brownclouds.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex12.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['halftonecell.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex15.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture tex15.png not found, falling back to tex03.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['murkywater.frag.glsl', 'volumetricexplosion.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex16.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'bloodyriver.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex17a.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)



                    elif shader in ['discswallpaper.frag.glsl', 'biowall.frag.glsl', 'octopus.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex17.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)



                    elif shader == 'bubblefloat.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex18.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex17.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['caverocks.frag.glsl', 'bonestructure.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex20.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['textdecode.frag.glsl', 'textdecode2.frag.glsl', 'trainview.frag.glsl', 'textdecode3.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex21.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)



                    elif shader in ['canyon.frag.glsl', 'planeteclipse.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex22.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader == 'truchetcell.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'envmap.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture envmap.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'flies.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'fly-static.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture fly-static.png not found for {shader}", xbmc.LOGERROR)

                    elif shader == 'kodimac.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'texkodi.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture envmap.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'runner.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'runner.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture runner.png not found, falling back to tex03.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)

                    elif shader == 'satphoto.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'satphoto.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex11.png not found for {shader}", xbmc.LOGWARNING)

                    elif shader in ['spaceship.frag.glsl', 'spaceshipdusk.frag.glsl', 'testershader.frag.glsl', 'vhsblues.frag.glsl', 'mountainsunrise.frag.glsl', 'coralcave.frag.glsl', 'spacecity.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex03.png')
                        if shader == 'vhsblues.frag.glsl':
                            texture_path = os.path.join(TEXTURE_PATH, 'vhs.png')
                        if not xbmcvfs.exists(texture_path):
                            xbmc.log(f"{ADDON_ID}: Texture {texture_path} not found, falling back to tex03a.png", xbmc.LOGWARNING)
                            texture_path = os.path.join(TEXTURE_PATH, 'tex03a.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture not found for {shader}", xbmc.LOGWARNING)
                    else: # Default for texture0 if no specific shader rule matches
                        setting.text = ''

                # Set texture1 (iChannel1) for specific shaders
                elif setting.get('id') == 'texture1':
                    if shader in ['drawerwall.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'tex23.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture1 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture fly-flying.png not found for {shader}", xbmc.LOGERROR)

                    # MODIFIED SECTION FOR paperlantern.frag.glsl iChannel1
                    elif shader == 'paperlantern.frag.glsl': # New dual-texture shader
                        texture_path = os.path.join(TEXTURE_PATH, 'tex08.png') # Correct texture for iChannel1
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture1 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex08.png not found for {shader}", xbmc.LOGWARNING) # Corrected log
                    # END MODIFIED SECTION FOR paperlantern.frag.glsl iChannel1
                    else: # Default for texture1 if no specific shader rule matches
                        setting.text = ''


                # Clear other texture slots unless needed for other shaders
                elif setting.get('id') in ['texture2', 'texture3']:
                    setting.text = ''
            tree.write(SETTINGS_PATH)
            xbmc.log(f"{ADDON_ID}: Updated settings.xml with shader {shader}", xbmc.LOGINFO)
        except Exception as e:
            xbmc.log(f"{ADDON_ID}: Failed to update settings.xml: {str(e)}", xbmc.LOGERROR)

    def set_shader(self, shader):
        if not xbmcvfs.exists(os.path.join(SHADER_PATH, shader)):
            xbmc.log(f"{ADDON_ID}: Shader {shader} not found", xbmc.LOGERROR)
            return
        xbmc.log(f"{ADDON_ID}: Attempting to set shader to {shader}", xbmc.LOGINFO)
        self.update_settings_xml(shader)
        self.current_shader = shader
        xbmc.sleep(100) # Give Kodi a moment to process the settings change
        screensaver_active = xbmc.getCondVisibility('System.ScreenSaverActive')
        xbmc.log(f"{ADDON_ID}: Screensaver active: {screensaver_active}, is_cycling: {self.is_cycling}", xbmc.LOGINFO)
        if screensaver_active:
            self.is_cycling = True # Set flag to prevent re-triggering cycle on reactivation
            self.is_refreshing = True # Indicate that this is a programmatic refresh
            xbmc.executebuiltin('DeactivateScreensaver')
            xbmc.sleep(2000) # Give it time to deactivate
            xbmc.executebuiltin('ActivateScreensaver')
            xbmc.log(f"{ADDON_ID}: Refreshed screensaver for {shader}", xbmc.LOGINFO)
            self.is_refreshing = False
            self.is_cycling = False # Reset flag after cycling attempt
        else:
            xbmc.log(f"{ADDON_ID}: Skipping refresh, screensaver not active", xbmc.LOGINFO)

    def cycle_shaders(self):
        if not self.all_shaders:
            xbmc.log(f"{ADDON_ID}: No shaders to cycle in the master list", xbmc.LOGERROR)
            return
        if self.is_cycling:
            xbmc.log(f"{ADDON_ID}: Already cycling, skipping", xbmc.LOGINFO)
            return

        self.is_cycling = True # Set flag to indicate a cycle is in progress

        if SetToTester == 1:
            next_shader = TESTER_SHADER
            xbmc.log(f"{ADDON_ID}: SetToTester enabled, using {next_shader}", xbmc.LOGINFO)
        else:
            # If the current batch of shaders is exhausted, reshuffle the master list
            # and start a new batch.
            if not self.remaining_shaders:
                xbmc.log(f"{ADDON_ID}: All shaders in current batch cycled. Reshuffling for a new batch.", xbmc.LOGINFO)
                random.shuffle(self.all_shaders) # Reshuffle the master list
                self.remaining_shaders = list(self.all_shaders) # Populate with a new copy

            next_shader = self.remaining_shaders.pop(0) # Get the next shader from the batch

            # Optional: Ensure the next_shader is not the same as the current_shader
            # This handles cases where the pop(0) gives you the same shader that was just active.
            # It also makes sure there's more than one shader left to pick from to avoid an infinite loop
            # if only one shader remains and it happens to be the current one.
            if next_shader == self.current_shader and len(self.remaining_shaders) > 0:
                xbmc.log(f"{ADDON_ID}: Next shader from batch ({next_shader}) is same as current. Re-adding to end and picking again.", xbmc.LOGINFO)
                self.remaining_shaders.append(next_shader) # Put it back to ensure it gets seen later
                # We can reshuffle the remaining list to ensure the next pick is truly random
                # among the remaining, or just let it naturally cycle. Shuffling is safer.
                random.shuffle(self.remaining_shaders)
                next_shader = self.remaining_shaders.pop(0)


            xbmc.log(f"{ADDON_ID}: Cycling to {next_shader}. {len(self.remaining_shaders)} shaders remaining in current batch.", xbmc.LOGINFO)

        self.set_shader(next_shader)
        self.is_cycling = False # Reset flag after cycling attempt

    def onScreensaverActivated(self):
        xbmc.log(f"{ADDON_ID}: Screensaver activated", xbmc.LOGINFO)
        if self.is_refreshing:
            xbmc.log(f"{ADDON_ID}: Ignoring activation due to refresh by cycler", xbmc.LOGINFO)
            return
        if not self.screensaver_started:
            xbmc.log(f"{ADDON_ID}: First screensaver activation (not a refresh), starting cycle", xbmc.LOGINFO)
            self.screensaver_started = True
            self.cycle_shaders()
            self.last_cycle = time.time() # Update last_cycle after first shader is set

    def onScreensaverDeactivated(self):
        xbmc.log(f"{ADDON_ID}: Screensaver deactivated", xbmc.LOGINFO)
        self.screensaver_started = False
        self.is_cycling = False # Ensure cycling flag is reset on deactivation

if __name__ == '__main__':
    xbmc.log(f"{ADDON_ID}: Starting shader cycler service", xbmc.LOGINFO)
    monitor = ShaderCycler()
    last_log = time.time()
    while not monitor.abortRequested():
        current_time = time.time()
        # Log status periodically
        if current_time - last_log >= LOG_INTERVAL:
            xbmc.log(f"{ADDON_ID}: Service Running. Current shader: {monitor.current_shader}. Shaders in batch: {len(monitor.remaining_shaders)}", xbmc.LOGINFO)
            last_log = current_time

        # Only cycle if not in tester mode and interval passed and screensaver is active
        if SetToTester == 0 and current_time - monitor.last_cycle >= CYCLE_INTERVAL:
            if xbmc.getCondVisibility('System.ScreenSaverActive'):
                monitor.cycle_shaders()
                monitor.last_cycle = current_time # Reset the timer only after a successful cycle

        monitor.waitForAbort(1) # Wait for 1 second, allowing Kodi to signal abortion
    xbmc.log(f"{ADDON_ID}: Stopping shader cycler service", xbmc.LOGINFO)