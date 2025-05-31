import xbmc
import xbmcaddon
import xbmcvfs
import os
import random
import time
import xml.etree.ElementTree as ET

ADDON = xbmcaddon.Addon()
ADDON_ID = ADDON.getAddonInfo('id')  # Will be "service.shadertoy.cycler"
SHADER_PATH = xbmcvfs.translatePath('special://home/addons/screensaver.shadertoy/resources/shaders/')
SETTINGS_PATH = "/storage/.kodi/userdata/addon_data/screensaver.shadertoy/settings.xml"
TEXTURE_PATH = xbmcvfs.translatePath('special://home/addons/screensaver.shadertoy/resources/')
CYCLE_INTERVAL = 150  # 10 seconds as set
LOG_INTERVAL = 30    # Log every 30 seconds
SetToTester = 0      # Set to 1 to use only testershader.frag.glsl, 0 to cycle through FIXED_SHADERS

#*  Hernando - Notes on Customizing
#    after any change, Kodi must be restarted. use this to re-start: 
#       systemctl restart kodi
# to check kodi log to diagnose shaders:   cat /storage/.kodi/temp/kodi.log

#
#   Texture extraction command in Libreelec:   
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
# Fixed list of shaders from the Shadertoy addon (excluding main*.* files)
FIXED_SHADERS = [
    '0gfire.frag.glsl',
    '3dspheres.frag.glsl',
    '3dstudio.frag.glsl',
    '50ssitcom.frag.glsl',
    'abovetheclouds.frag.glsl',
    'abstractcells.frag.glsl',
    'acvent.frag.glsl',
    'acrylicubes.frag.glsl',
    'amoebas.frag.glsl',
    'anemone.frag.glsl',
    'angrycloud.frag.glsl',
    'anothertanh.frag.glsl',
    'approachingheaven.frag.glsl',
    'arabesque.frag.glsl',
    'artdeco.frag.glsl',
    'ashfall.frag.glsl',
    'ball.frag.glsl',
    'balloffire.frag.glsl',
    'basilica.frag.glsl',
    'bathiscaph.frag.glsl',
    'bicycle.frag.glsl',
    'blackholesun.frag.glsl',
    'blacktar.frag.glsl',
    'bleepyblocks.frag.glsl',
    'blobs.frag.glsl',
    'bluefire.frag.glsl',
    'bouncingballs.frag.glsl',
    'camofur.frag.glsl',
    'campfire.frag.glsl',
    'cartography.frag.glsl',
    'cellular.frag.glsl',
    'closeencounters.frag.glsl',
    'clouds.frag.glsl',
    'conception.frag.glsl',    
    'constellations.frag.glsl',
    'constellationsinverted.frag.glsl',
    'constellations2.frag.glsl',
    'coralreef.frag.glsl',
    'corona.frag.glsl',
    'crescentmoon.frag.glsl',
    'cubelights.frag.glsl',
    'cubism.frag.glsl',
    'digitalboard.frag.glsl',
    'digitvortex.frag.glsl',
    'discswallpaper.frag.glsl',
    'drawingbezier.frag.glsl',
    'dunes.frag.glsl',
    'dvdretro.frag.glsl',
    'dvdretro-nonoise.frag.glsl',
    'ether.frag.glsl',
    'eventhorizon.frag.glsl',
    'fantasticvoyage.frag.glsl',
    'favela.frag.glsl',
    'fibonacisphere.frag.glsl',
    'fire.frag.glsl',
    'fireghost.frag.glsl',
    'fishbones.frag.glsl',
    'flashcards.frag.glsl',
    'flatbelts.frag.glsl',
    'flowingpaint.frag.glsl',
    'fractaltiling.frag.glsl',
    'fur.frag.glsl',
    'gears.frag.glsl',
    'giraffefur.frag.glsl',
    'goldensection.frag.glsl',
    'goldrain.frag.glsl',
    'greenslime.frag.glsl', 
    'guildnavigator.frag.glsl',     
    'handsketch.frag.glsl',  
    'hallofmirrors.frag.glsl',  
    'halftonecell.frag.glsl',  
    'hangingart.frag.glsl',
    'happycloud.frag.glsl',  
    'hatchery.frag.glsl',  
    'heavenly.frag.glsl',    
    'heavenly.frag.glsl',    
    'illuminatedsphere.frag.glsl',
    'infinitefall.frag.glsl',
    'infinitycube.frag.glsl',
    'inthetornado.frag.glsl',
    'intothemint.frag.glsl',
    'jetsons.frag.glsl',
    'juliatrap.frag.glsl',
    'kite.frag.glsl',
    'lateeze.frag.glsl',
    'lavalamp.frag.glsl',
    'leather.frag.glsl',
    'liquidspectrum.frag.glsl',
    'liquidspectrum-mono.frag.glsl',   
    'lizardskin.frag.glsl',
    'lostsoldier.frag.glsl',
    'maibuterflai.frag.glsl',    
    'mandala.frag.glsl',    
    'mandala2.frag.glsl',    
    'mandel.frag.glsl',    
    'mandelbrot.frag.glsl',    
    'mellowvoronoi.frag.glsl',
    'metalblocks.frag.glsl',
    'mosaictiles.frag.glsl',
    'mrbert.frag.glsl',
    'mrbouncy.frag.glsl',
    'murkywater.frag.glsl',
    'nebulaflight.frag.glsl',
    'nebulaflight2.frag.glsl',
    'nebulosa.frag.glsl',
    'neonknights.frag.glsl',
    'nestedspheres.frag.glsl',
    'newenergy.frag.glsl',
    'nightdive.frag.glsl',
    'nightsea.frag.glsl',
    'noiseanimelava.frag.glsl',
    'nubela.frag.glsl',
    'origamikaleidoscope.frag.glsl',
    'origamishift.frag.glsl',
    'outerlimits.frag.glsl',
    'paislymilk.frag.glsl',
    'paistropical.frag.glsl',
    'palettes.frag.glsl',
    'pantonechips.frag.glsl',
    'paperairplanes.frag.glsl',
    'paperkaleidoscope.frag.glsl',
    'paperwaterfall.frag.glsl',
    'partlycloudy.frag.glsl',
    'pcb.frag.glsl',
    'permutations.frag.glsl',
    'picassoblocks.frag.glsl',
    'planetarium.frag.glsl', 
    'plutoniancells.frag.glsl', 
    'popart.frag.glsl',
    'quadtruchet.frag.glsl',
    'radar.frag.glsl',
    'radarr.frag.glsl',
    'rainyheadlights.frag.glsl',
    'redvelvet.frag.glsl',
    'rendering.frag.glsl',
    'rings.frag.glsl',    
    'ringworms.frag.glsl',    
    'ringworms2.frag.glsl',  
    'rolling.frag.glsl',
    'ropes.frag.glsl',
    'rorshak.frag.glsl',
    'rorshak2.frag.glsl',
    'salgarnight.frag.glsl',
    'sea.frag.glsl',
    'seaurchin.frag.glsl',
    'sepiasky.frag.glsl',
    'silexarst.frag.glsl',
    'singularity.frag.glsl',
    'singularity2.frag.glsl',
    'skulltv.frag.glsl',
    'smiley.frag.glsl',
    'smokeonthewater.frag.glsl',
    'snowfall.frag.glsl',
    'sonarr.frag.glsl',
    'spectrumzoom.frag.glsl',
    'succulent.frag.glsl',    
    'summitday.frag.glsl',    
    'sunset.frag.glsl',
    'suntiles.frag.glsl',
    'tiedye.frag.glsl',
    'timetunnel.frag.glsl',
    'tool.frag.glsl',
    'tool2.frag.glsl',
    'trippinbee.frag.glsl',
    'truchetcell.frag.glsl',
    'tunelandthelight.frag.glsl',
    'tunellight.frag.glsl',
    'twistedknot.frag.glsl',
    'unicornneurons.frag.glsl',
    'venus.frag.glsl',
    'viralblob.frag.glsl',
    'viralblob-red.frag.glsl',
    'voronoid.frag.glsl',
    'windysun.frag.glsl',
    'woodblocks.frag.glsl',
    'worleynoisewaters.frag.glsl',
    'singularity.frag.glsl',
    'smiley.frag.glsl',
    'spaceship.frag.glsl',
    'spaceshipdusk.frag.glsl',
    'spaceshipv2.frag.glsl',
    'theshining.frag.glsl',
    'thetwilight.frag.glsl',
    'time.frag.glsl',
    'kaleidoscope.frag.glsl',
    'kaleidoscope-inv.frag.glsl',
    'shootingstars.frag.glsl',
    'underice.frag.glsl',
    'vitals.frag.glsl',
    'voronoicubes.frag.glsl',
    'waveform.frag.glsl',
    'wet.frag.glsl',
    'whirl.frag.glsl',
    'yingyang.frag.glsl',
    'zen.frag.glsl',

    'ribbons.frag.glsl',
    'seismograph.frag.glsl',
    'vhsblues.frag.glsl',

    'testershader.frag.glsl',
   
    # Added new dual-texture shader (replace with actual filename)
   # 'dualtexture.frag.glsl'  # Placeholder for the new shader using iChannel0 and iChannel1
]

TESTER_SHADER = 'testershader.frag.glsl'  # Set for testing

class ShaderCycler(xbmc.Monitor):
    def __init__(self):
        super().__init__()
        self.current_shader = ''
        self.shaders = FIXED_SHADERS
        self.is_cycling = False
        self.is_refreshing = False
        self.screensaver_started = False
        self.last_cycle = time.time()
        xbmc.log(f"{ADDON_ID}: Initializing ShaderCycler", xbmc.LOGINFO)
        self.load_shaders()
        if self.shaders:
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
            for shader in self.shaders:
                if xbmcvfs.exists(os.path.join(SHADER_PATH, shader)):
                    valid_shaders.append(shader)
                else:
                    xbmc.log(f"{ADDON_ID}: Shader {shader} not found in {SHADER_PATH}, skipping", xbmc.LOGWARNING)
        self.shaders = valid_shaders
        if not self.shaders:
            xbmc.log(f"{ADDON_ID}: No valid shaders found", xbmc.LOGERROR)
        else:
            xbmc.log(f"{ADDON_ID}: Loaded {len(self.shaders)} shaders: {self.shaders}", xbmc.LOGINFO)

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
                    if shader in ['eventhorizon.frag.glsl', 'mistymountainhop.frag.glsl']:
                        # For eventhorizon, prioritize tex03a.png
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
                    elif shader in ['runner.frag.glsl']:
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
                    elif shader == 'truchetcell.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'envmap.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture envmap.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'rorshak2.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex11.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex11.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'discswallpaper.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex17.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex17.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'fur.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex01.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex01.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'leather.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex19.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex19.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'woodblocks.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex05.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex05.png not found for {shader}", xbmc.LOGWARNING)
 


                    elif shader == 'murkywater.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex16.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader == 'permutations.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex12.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)



                    elif shader == 'paperwaterfall.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex00.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex16.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader == 'ropes.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'metalblocks.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == 'picassoblocks.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex02.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex02.png not found for {shader}", xbmc.LOGWARNING)
                    elif shader == '50ssitcom.frag.glsl':
                        texture_path = os.path.join(TEXTURE_PATH, 'tex12.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex12.png not found for {shader}", xbmc.LOGWARNING)


                    elif shader in ['spaceship.frag.glsl', 'spaceshipdusk.frag.glsl', 'testershader.frag.glsl', 'vhsblues.frag.glsl']:
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


                    elif shader in ['flies.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'fly-static.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture fly-static.png not found for {shader}", xbmc.LOGERROR)


                    elif shader == 'dualtexture.frag.glsl':  # New dual-texture shader
                        texture_path = os.path.join(TEXTURE_PATH, 'tex16.png')  # Placeholder for iChannel0
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture0 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex03.png not found for {shader}", xbmc.LOGWARNING)
                    else:
                        setting.text = ''


 #########################
                # Set texture1 (iChannel1) for specific shaders
                elif setting.get('id') == 'texture1':
                    if shader in ['flies.frag.glsl']:
                        texture_path = os.path.join(TEXTURE_PATH, 'fly-flying.png')
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture1 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture fly-flying.png not found for {shader}", xbmc.LOGERROR)



                    elif shader == 'dualtexture.frag.glsl':  # New dual-texture shader
                        texture_path = os.path.join(TEXTURE_PATH, 'snarf.png')  # Placeholder for iChannel1
                        if xbmcvfs.exists(texture_path):
                            setting.text = texture_path
                            xbmc.log(f"{ADDON_ID}: Set texture1 to {texture_path} for {shader}", xbmc.LOGINFO)
                        else:
                            setting.text = ''
                            xbmc.log(f"{ADDON_ID}: Texture tex04.png not found for {shader}", xbmc.LOGWARNING)
                    else:
                        setting.text = ''


 #########################




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
        xbmc.sleep(100)
        screensaver_active = xbmc.getCondVisibility('System.ScreenSaverActive')
        xbmc.log(f"{ADDON_ID}: Screensaver active: {screensaver_active}, is_cycling: {self.is_cycling}", xbmc.LOGINFO)
        if screensaver_active:
            self.is_cycling = True
            self.is_refreshing = True
            xbmc.executebuiltin('DeactivateScreensaver')
            xbmc.sleep(2000)
            xbmc.executebuiltin('ActivateScreensaver')
            xbmc.log(f"{ADDON_ID}: Refreshed screensaver for {shader}", xbmc.LOGINFO)
            self.is_refreshing = False
            self.is_cycling = False
        else:
            xbmc.log(f"{ADDON_ID}: Skipping refresh, screensaver not active", xbmc.LOGINFO)

    def cycle_shaders(self):
        if not self.shaders:
            xbmc.log(f"{ADDON_ID}: No shaders to cycle", xbmc.LOGERROR)
            return
        if self.is_cycling:
            xbmc.log(f"{ADDON_ID}: Already cycling, skipping", xbmc.LOGINFO)
            return
        self.is_cycling = True
        if SetToTester == 1:
            next_shader = TESTER_SHADER
            xbmc.log(f"{ADDON_ID}: SetToTester enabled, using {next_shader}", xbmc.LOGINFO)
        else:
            random.shuffle(self.shaders)
            next_shader = self.shaders[0]
            if next_shader == self.current_shader and len(self.shaders) > 1:
                next_shader = self.shaders[1]
            xbmc.log(f"{ADDON_ID}: Cycling to {next_shader}", xbmc.LOGINFO)
        self.set_shader(next_shader)
        xbmc.log(f"{ADDON_ID}: Cycled to {next_shader}, order: {self.shaders[:5]}...", xbmc.LOGINFO)
        self.is_cycling = False

    def onScreensaverActivated(self):
        xbmc.log(f"{ADDON_ID}: Screensaver activated", xbmc.LOGINFO)
        if self.is_refreshing:
            xbmc.log(f"{ADDON_ID}: Ignoring activation due to refresh", xbmc.LOGINFO)
            return
        if not self.screensaver_started:
            xbmc.log(f"{ADDON_ID}: First screensaver activation, starting cycle", xbmc.LOGINFO)
            self.screensaver_started = True
            self.cycle_shaders()
            self.last_cycle = time.time()

    def onScreensaverDeactivated(self):
        xbmc.log(f"{ADDON_ID}: Screensaver deactivated", xbmc.LOGINFO)
        self.screensaver_started = False

if __name__ == '__main__':
    xbmc.log(f"{ADDON_ID}: Starting shader cycler service", xbmc.LOGINFO)
    monitor = ShaderCycler()
    last_log = time.time()
    while not monitor.abortRequested():
        current_time = time.time()
        if current_time - last_log >= LOG_INTERVAL:
            xbmc.log(f"{ADDON_ID}: Running, current: {monitor.current_shader}", xbmc.LOGINFO)
            last_log = current_time
        if SetToTester == 0 and current_time - monitor.last_cycle >= CYCLE_INTERVAL:
            if xbmc.getCondVisibility('System.ScreenSaverActive'):
                monitor.cycle_shaders()
                monitor.last_cycle = current_time
        monitor.waitForAbort(1)
    xbmc.log(f"{ADDON_ID}: Stopping shader cycler service", xbmc.LOGINFO)