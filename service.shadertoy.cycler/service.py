import xbmc
import xbmcaddon
import time
import random

addon = xbmcaddon.Addon('screensaver.shadertoy')
shader_list = [
    'agalaxy.frag.glsl', 'ball.frag.glsl', 'balloffire.frag.glsl', 'bleepyblocks.frag.glsl',
    'blobs.frag.glsl', 'bluefire.frag.glsl', 'cellular.frag.glsl', 'colorcircles.frag.glsl',
    'dancefloor.frag.glsl', 'dotdotdot.frag.glsl', 'ether.frag.glsl', 'etherGEAR.frag.glsl',
    'fire.frag.glsl', 'flaringtype1.frag.glsl', 'flaringtype2.frag.glsl', 'flaringtype3.frag.glsl',
    'flaringtype4.frag.glsl', 'flaringtype5.frag.glsl', 'fractaltiling.frag.glsl', 'infinitefall.frag.glsl',
    'inputtime.frag.glsl', 'juliatrap.frag.glsl', 'noiseanimelectric.frag.glsl', 'noiseanimlava.frag.glsl',
    'noiseanimwatery.frag.glsl', 'pixellated.frag.glsl', 'plasmacircles.frag.glsl', 'plasmatriangle.frag.glsl',
    'rgbplasma.frag.glsl', 'sphere.frag.glsl', 'startunnel.frag.glsl', 'stellar.frag.glsl',
    'vectorfield.frag.glsl', 'watercaustic.frag.glsl'
]

def cycle_shaders():
    monitor = xbmc.Monitor()
    xbmc.log("Shadertoy Cycler: Starting cycler v10", xbmc.LOGINFO)
    last_switch = time.time() - 300  # Start ready to switch
    last_log = 0  # For reducing log spam
    while not monitor.abortRequested():
        current_time = time.time()
        elapsed = current_time - last_switch
        # Log only every 30 seconds
        if current_time - last_log >= 30:
            xbmc.log("Shadertoy Cycler: Checking - elapsed %.1f" % elapsed, xbmc.LOGINFO)
            last_log = current_time
        # Switch shader every 5 minutes (300 seconds)
        if xbmc.getCondVisibility('System.ScreenSaverActive') and elapsed >= 300:
            shader = random.choice(shader_list)
            addon.setSetting('settings_shader', shader)
            xbmc.log("Shadertoy Cycler: Set shader to %s" % shader, xbmc.LOGINFO)
            xbmc.executebuiltin('Action(Stop)')
            time.sleep(0.2)
            xbmc.executebuiltin('ActivateScreensaver')
            active_shader = addon.getSetting('settings_shader')
            xbmc.log("Shadertoy Cycler: Active shader is %s" % active_shader, xbmc.LOGINFO)
            last_switch = current_time
        elif not xbmc.getCondVisibility('System.ScreenSaverActive'):
            last_switch = current_time  # Reset timer when screensaver is off
        time.sleep(1)
    xbmc.log("Shadertoy Cycler: Stopped", xbmc.LOGINFO)

if __name__ == '__main__':
    try:
        cycle_shaders()
    except Exception as e:
        xbmc.log("Shadertoy Cycler: Error - %s" % str(e), xbmc.LOGERROR)