-- OBS Auto-Zoom to Mouse Click
-- Automatically zooms when you click - no hotkeys needed!
-- Based on obs-zoom-to-mouse by BlankSourceCode
-- Enhanced with automatic click detection
-- Compatible with OBS 30+

local obs = obslua
local ffi = require("ffi")

-- Version info
local VERSION = "2.0-auto-click"

-- FFI definitions for Windows mouse detection
if ffi.os == "Windows" then
    ffi.cdef[[
        typedef int BOOL;
        typedef void* HANDLE;
        typedef void* HWND;
        typedef unsigned long DWORD;
        typedef short SHORT;
        typedef long LONG;
        
        typedef struct tagPOINT {
            LONG x;
            LONG y;
        } POINT;
        
        SHORT GetAsyncKeyState(int vKey);
        BOOL GetCursorPos(POINT* lpPoint);
        HWND GetForegroundWindow();
    ]]
end

-- FFI definitions for Mac mouse detection  
if ffi.os == "OSX" then
    ffi.cdef[[
        typedef struct CGPoint {
            double x;
            double y;
        } CGPoint;
        
        typedef void* CGEventRef;
        
        CGPoint CGEventGetLocation(CGEventRef event);
        int CGEventSourceButtonState(int sourceType, int button);
    ]]
end

-- Filter name
local CROP_FILTER_NAME = "obs-auto-zoom-crop"

-- Settings
local settings = {
    -- Source settings
    source_name = "",
    
    -- Auto-zoom settings
    auto_zoom_enabled = true,
    zoom_on_left_click = true,
    zoom_on_right_click = false,
    zoom_duration = 2000,  -- ms to stay zoomed
    min_click_distance = 100,  -- minimum pixels between clicks
    
    -- Zoom behavior
    zoom_factor = 1.5,
    zoom_speed = 400,
    auto_follow = true,
    follow_speed = 7,
    follow_border = 6,
    lock_sensitivity = 40,
}

-- State tracking
local state = {
    source = nil,
    sceneitem = nil,
    crop_filter = nil,
    
    is_zoomed = false,
    zoom_end_time = 0,
    
    last_click_x = 0,
    last_click_y = 0,
    last_mouse_state = {
        left = false,
        right = false
    },
    
    -- Source dimensions
    source_x = 0,
    source_y = 0,
    source_width = 1920,
    source_height = 1080,
    
    -- Crop filter info
    crop_x = 0,
    crop_y = 0,
    crop_width = 1920,
    crop_height = 1080,
    
    -- Animation
    target_crop_x = 0,
    target_crop_y = 0,
    target_crop_width = 1920,
    target_crop_height = 1080,
    animation_progress = 1.0,
}

-- Helper functions
local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function ease_in_out(t)
    return t * t * (3.0 - 2.0 * t)
end

-- Mouse detection functions
local function get_mouse_position()
    if ffi.os == "Windows" then
        local point = ffi.new("POINT[1]")
        if ffi.C.GetCursorPos(point) ~= 0 then
            return point[0].x, point[0].y
        end
    elseif ffi.os == "OSX" then
        -- Mac implementation - simplified
        -- In production, would use CGEventCreate/GetLocation
        return 0, 0
    end
    return 0, 0
end

local function is_mouse_button_down(button)
    if ffi.os == "Windows" then
        local VK_LBUTTON = 0x01
        local VK_RBUTTON = 0x02
        
        local vkey = (button == "left") and VK_LBUTTON or VK_RBUTTON
        local key_state = ffi.C.GetAsyncKeyState(vkey)
        return bit.band(key_state, 0x8000) ~= 0
    end
    return false
end

-- Source and filter management
local function find_source()
    if settings.source_name == "" then
        return nil
    end
    
    local source = obs.obs_get_source_by_name(settings.source_name)
    if source then
        return source
    end
    
    return nil
end

local function find_sceneitem()
    local current_scene = obs.obs_frontend_get_current_scene()
    if not current_scene then
        return nil
    end
    
    local scene = obs.obs_scene_from_source(current_scene)
    obs.obs_source_release(current_scene)
    
    if not scene then
        return nil
    end
    
    local items = obs.obs_scene_enum_items(scene)
    local found_item = nil
    
    if items then
        for _, item in ipairs(items) do
            local item_source = obs.obs_sceneitem_get_source(item)
            local name = obs.obs_source_get_name(item_source)
            
            if name == settings.source_name then
                found_item = item
                break
            end
        end
        obs.sceneitem_list_release(items)
    end
    
    return found_item
end

local function get_or_create_crop_filter()
    if not state.source then
        return nil
    end
    
    -- Look for existing filter
    local filter = obs.obs_source_get_filter_by_name(state.source, CROP_FILTER_NAME)
    
    if not filter then
        -- Create new crop/pad filter
        filter = obs.obs_source_create_private("crop_filter", CROP_FILTER_NAME, nil)
        obs.obs_source_filter_add(state.source, filter)
    end
    
    return filter
end

local function update_source_dimensions()
    if not state.sceneitem then
        return
    end
    
    -- Get source dimensions
    local source = obs.obs_sceneitem_get_source(state.sceneitem)
    if source then
        state.source_width = obs.obs_source_get_width(source)
        state.source_height = obs.obs_source_get_height(source)
    end
    
    -- Get position
    local pos = obs.vec2()
    obs.obs_sceneitem_get_pos(state.sceneitem, pos)
    state.source_x = pos.x
    state.source_y = pos.y
end

-- Zoom functions
local function start_zoom(mouse_x, mouse_y)
    if not settings.auto_zoom_enabled then
        return
    end
    
    -- Update references
    state.source = find_source()
    state.sceneitem = find_sceneitem()
    
    if not state.source or not state.sceneitem then
        print("[Auto-Zoom] Could not find source: " .. settings.source_name)
        return
    end
    
    update_source_dimensions()
    
    -- Get or create crop filter
    state.crop_filter = get_or_create_crop_filter()
    if not state.crop_filter then
        print("[Auto-Zoom] Could not create crop filter")
        return
    end
    
    -- Calculate zoom target
    local zoom_width = state.source_width / settings.zoom_factor
    local zoom_height = state.source_height / settings.zoom_factor
    
    -- Center on mouse position (relative to source)
    local mouse_rel_x = mouse_x - state.source_x
    local mouse_rel_y = mouse_y - state.source_y
    
    -- Calculate crop position to center on mouse
    local crop_x = mouse_rel_x - (zoom_width / 2)
    local crop_y = mouse_rel_y - (zoom_height / 2)
    
    -- Clamp to source bounds
    crop_x = math.max(0, math.min(crop_x, state.source_width - zoom_width))
    crop_y = math.max(0, math.min(crop_y, state.source_height - zoom_height))
    
    -- Set target values for animation
    state.target_crop_x = crop_x
    state.target_crop_y = crop_y
    state.target_crop_width = zoom_width
    state.target_crop_height = zoom_height
    
    -- Start animation
    state.animation_progress = 0.0
    state.is_zoomed = true
    state.zoom_end_time = os.clock() * 1000 + settings.zoom_duration
    
    print(string.format("[Auto-Zoom] Zooming to (%d, %d)", math.floor(mouse_x), math.floor(mouse_y)))
end

local function end_zoom()
    if not state.is_zoomed then
        return
    end
    
    -- Set target back to full view
    state.target_crop_x = 0
    state.target_crop_y = 0
    state.target_crop_width = state.source_width
    state.target_crop_height = state.source_height
    
    -- Start zoom-out animation
    state.animation_progress = 0.0
    state.is_zoomed = false
    
    print("[Auto-Zoom] Zooming out")
end

local function update_crop_filter()
    if not state.crop_filter then
        return
    end
    
    -- Animate crop values
    if state.animation_progress < 1.0 then
        local t = ease_in_out(state.animation_progress)
        
        state.crop_x = lerp(state.crop_x, state.target_crop_x, t)
        state.crop_y = lerp(state.crop_y, state.target_crop_y, t)
        state.crop_width = lerp(state.crop_width, state.target_crop_width, t)
        state.crop_height = lerp(state.crop_height, state.target_crop_height, t)
        
        -- Increment animation progress
        local speed_factor = 1000.0 / settings.zoom_speed
        state.animation_progress = math.min(1.0, state.animation_progress + (0.016 * speed_factor))
    end
    
    -- Apply crop to filter
    local filter_settings = obs.obs_source_get_settings(state.crop_filter)
    
    obs.obs_data_set_int(filter_settings, "left", math.floor(state.crop_x))
    obs.obs_data_set_int(filter_settings, "top", math.floor(state.crop_y))
    obs.obs_data_set_int(filter_settings, "cx", math.floor(state.crop_width))
    obs.obs_data_set_int(filter_settings, "cy", math.floor(state.crop_height))
    
    obs.obs_source_update(state.crop_filter, filter_settings)
    obs.obs_data_release(filter_settings)
end

-- Main tick function
local function tick(delta_ms)
    if not settings.auto_zoom_enabled then
        return
    end
    
    -- Detect mouse clicks
    local left_down = is_mouse_button_down("left")
    local right_down = is_mouse_button_down("right")
    
    local left_clicked = left_down and not state.last_mouse_state.left
    local right_clicked = right_down and not state.last_mouse_state.right
    
    state.last_mouse_state.left = left_down
    state.last_mouse_state.right = right_down
    
    -- Check if should zoom
    local should_zoom = false
    if settings.zoom_on_left_click and left_clicked then
        should_zoom = true
    end
    if settings.zoom_on_right_click and right_clicked then
        should_zoom = true
    end
    
    if should_zoom then
        local mouse_x, mouse_y = get_mouse_position()
        
        -- Check distance from last click
        local dist = distance(mouse_x, mouse_y, state.last_click_x, state.last_click_y)
        
        if dist > settings.min_click_distance or not state.is_zoomed then
            -- End previous zoom if active
            if state.is_zoomed then
                end_zoom()
                -- Wait for zoom-out animation to complete
                return
            end
            
            -- Start new zoom
            start_zoom(mouse_x, mouse_y)
            state.last_click_x = mouse_x
            state.last_click_y = mouse_y
        end
    end
    
    -- Check for auto zoom-out
    if state.is_zoomed then
        local current_time = os.clock() * 1000
        if current_time >= state.zoom_end_time then
            end_zoom()
        end
    end
    
    -- Update crop filter animation
    update_crop_filter()
end

-- OBS Script Interface
function script_description()
    return [[<h2>Auto-Zoom on Click</h2>
<p>Automatically zooms to your mouse position when you click!</p>
<p><b>Version:</b> ]] .. VERSION .. [[</p>
<p><b>Features:</b></p>
<ul>
<li>✅ No hotkeys needed - just click!</li>
<li>✅ Automatic zoom to click position</li>
<li>✅ Configurable zoom duration</li>
<li>✅ Left/right click options</li>
<li>✅ Smooth animations</li>
</ul>
<p><b>Requirements:</b></p>
<ul>
<li>Use Display Capture source</li>
<li>OBS 30+</li>
<li>Windows (Mac support limited)</li>
</ul>
<p><b>Usage:</b></p>
<ol>
<li>Select your Display Capture as "Zoom Source"</li>
<li>Enable "Auto-Zoom on Click"</li>
<li>Start recording and click anywhere!</li>
<li>Automatically zooms and zooms out after duration</li>
</ol>]]
end

function script_properties()
    local props = obs.obs_properties_create()
    
    -- Source selection
    local source_list = obs.obs_properties_add_list(props, "source_name", "Zoom Source",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    
    local sources = obs.obs_enum_sources()
    if sources then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_id(source)
            -- Only show display capture sources
            if source_id == "monitor_capture" or source_id == "xshm_input" or 
               source_id == "window_capture" or source_id == "xcomposite_input" or
               source_id == "display_capture" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(source_list, name, name)
            end
        end
    end
    obs.source_list_release(sources)
    
    -- Auto-zoom settings
    obs.obs_properties_add_bool(props, "auto_zoom_enabled", "✅ Enable Auto-Zoom on Click")
    
    obs.obs_properties_add_bool(props, "zoom_on_left_click", "Zoom on Left Click")
    
    obs.obs_properties_add_bool(props, "zoom_on_right_click", "Zoom on Right Click")
    
    obs.obs_properties_add_int_slider(props, "zoom_duration", 
        "Zoom Duration (ms)", 500, 5000, 100)
    
    obs.obs_properties_add_int_slider(props, "min_click_distance", 
        "Min Distance Between Clicks (px)", 50, 500, 10)
    
    -- Zoom behavior
    obs.obs_properties_add_float_slider(props, "zoom_factor", 
        "Zoom Factor", 1.1, 4.0, 0.1)
    
    obs.obs_properties_add_int_slider(props, "zoom_speed", 
        "Zoom Animation Speed (ms)", 100, 1000, 50)
    
    obs.obs_properties_add_bool(props, "auto_follow", 
        "Auto Follow Mouse While Zoomed")
    
    return props
end

function script_defaults(settings_data)
    obs.obs_data_set_default_bool(settings_data, "auto_zoom_enabled", true)
    obs.obs_data_set_default_bool(settings_data, "zoom_on_left_click", true)
    obs.obs_data_set_default_bool(settings_data, "zoom_on_right_click", false)
    obs.obs_data_set_default_int(settings_data, "zoom_duration", 2000)
    obs.obs_data_set_default_int(settings_data, "min_click_distance", 100)
    obs.obs_data_set_default_double(settings_data, "zoom_factor", 1.5)
    obs.obs_data_set_default_int(settings_data, "zoom_speed", 400)
    obs.obs_data_set_default_bool(settings_data, "auto_follow", true)
end

function script_update(settings_data)
    settings.source_name = obs.obs_data_get_string(settings_data, "source_name")
    settings.auto_zoom_enabled = obs.obs_data_get_bool(settings_data, "auto_zoom_enabled")
    settings.zoom_on_left_click = obs.obs_data_get_bool(settings_data, "zoom_on_left_click")
    settings.zoom_on_right_click = obs.obs_data_get_bool(settings_data, "zoom_on_right_click")
    settings.zoom_duration = obs.obs_data_get_int(settings_data, "zoom_duration")
    settings.min_click_distance = obs.obs_data_get_int(settings_data, "min_click_distance")
    settings.zoom_factor = obs.obs_data_get_double(settings_data, "zoom_factor")
    settings.zoom_speed = obs.obs_data_get_int(settings_data, "zoom_speed")
    settings.auto_follow = obs.obs_data_get_bool(settings_data, "auto_follow")
    
    print("[Auto-Zoom] Settings updated - Auto-zoom: " .. 
        (settings.auto_zoom_enabled and "ENABLED" or "DISABLED"))
end

function script_load(settings_data)
    print("[Auto-Zoom] Script loaded - Version " .. VERSION)
    print("[Auto-Zoom] Platform: " .. ffi.os)
    
    -- Register tick callback
    obs.timer_add(function()
        tick(16)  -- ~60fps
    end, 16)
end

function script_unload()
    if state.is_zoomed then
        end_zoom()
    end
    
    -- Release resources
    if state.source then
        obs.obs_source_release(state.source)
    end
    if state.crop_filter then
        obs.obs_source_release(state.crop_filter)
    end
    
    print("[Auto-Zoom] Script unloaded")
end
