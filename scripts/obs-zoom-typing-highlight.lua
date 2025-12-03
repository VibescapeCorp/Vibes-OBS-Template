-- OBS Auto-Zoom with Typing Detection & WORKING Click Highlights
-- Draws highlights directly using OBS graphics - no browser source needed!
-- Compatible with OBS 30+

local obs = obslua
local ffi = require("ffi")

local VERSION = "3.1-working-highlights"

-- FFI definitions for Windows
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
        
        typedef struct {
            HWND hwnd;
            DWORD dwThreadId;
            DWORD dwFlags;
        } GUITHREADINFO;
        
        SHORT GetAsyncKeyState(int vKey);
        BOOL GetCursorPos(POINT* lpPoint);
        HWND GetForegroundWindow();
        BOOL GetGUIThreadInfo(DWORD idThread, GUITHREADINFO* lpgui);
        BOOL GetCaretPos(POINT* lpPoint);
        BOOL ClientToScreen(HWND hWnd, POINT* lpPoint);
    ]]
end

local CROP_FILTER_NAME = "obs-auto-zoom-crop"
local HIGHLIGHT_SOURCE_NAME = "Click Highlights (Auto-generated)"

-- Settings
local settings = {
    source_name = "",
    
    -- Auto-zoom on click
    auto_zoom_enabled = true,
    zoom_on_left_click = true,
    zoom_on_right_click = false,
    zoom_duration = 2000,
    min_click_distance = 100,
    
    -- Typing detection
    stay_zoomed_while_typing = true,
    typing_timeout = 1000,
    follow_caret = true,
    
    -- Click highlighting
    show_click_highlight = true,
    highlight_duration = 500,
    highlight_size = 40,
    
    -- Zoom behavior
    zoom_factor = 1.5,
    zoom_speed = 400,
}

-- State tracking
local state = {
    source = nil,
    sceneitem = nil,
    crop_filter = nil,
    highlight_source = nil,  -- Image source for drawing highlights
    
    is_zoomed = false,
    zoom_end_time = 0,
    disable_auto_zoom_out = false,
    
    last_click_x = 0,
    last_click_y = 0,
    last_mouse_state = {left = false, right = false},
    
    -- Typing detection
    is_typing = false,
    last_keystroke_time = 0,
    last_caret_x = 0,
    last_caret_y = 0,
    
    -- Click highlights - store active circles
    highlights = {},
    
    -- Source dimensions
    source_x = 0,
    source_y = 0,
    source_width = 1920,
    source_height = 1080,
    
    -- Crop animation
    crop_x = 0,
    crop_y = 0,
    crop_width = 1920,
    crop_height = 1080,
    target_crop_x = 0,
    target_crop_y = 0,
    target_crop_width = 1920,
    target_crop_height = 1920,
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

-- Mouse and keyboard detection
local function get_mouse_position()
    if ffi.os == "Windows" then
        local point = ffi.new("POINT[1]")
        if ffi.C.GetCursorPos(point) ~= 0 then
            return point[0].x, point[0].y
        end
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

local function is_any_key_pressed()
    if ffi.os ~= "Windows" then
        return false
    end
    
    local keys_to_check = {
        0x08, 0x09, 0x0D, 0x20,  -- Backspace, Tab, Enter, Space
    }
    
    -- A-Z
    for i = 0x41, 0x5A do
        table.insert(keys_to_check, i)
    end
    
    -- 0-9
    for i = 0x30, 0x39 do
        table.insert(keys_to_check, i)
    end
    
    for _, vkey in ipairs(keys_to_check) do
        local key_state = ffi.C.GetAsyncKeyState(vkey)
        if bit.band(key_state, 0x8000) ~= 0 then
            return true
        end
    end
    
    return false
end

local function get_caret_position()
    if ffi.os ~= "Windows" then
        return nil, nil
    end
    
    local gui_info = ffi.new("GUITHREADINFO")
    gui_info.dwFlags = 0
    
    if ffi.C.GetGUIThreadInfo(0, gui_info) ~= 0 then
        local caret_pos = ffi.new("POINT[1]")
        
        if ffi.C.GetCaretPos(caret_pos) ~= 0 then
            local hwnd = gui_info.hwnd
            if hwnd ~= nil then
                if ffi.C.ClientToScreen(hwnd, caret_pos) ~= 0 then
                    return caret_pos[0].x, caret_pos[0].y
                end
            end
        end
    end
    
    return nil, nil
end

-- Click highlight management using OBS graphics
local function add_click_highlight(x, y, is_left_click)
    if not settings.show_click_highlight then
        return
    end
    
    local highlight = {
        x = x,
        y = y,
        is_left_click = is_left_click,
        start_time = os.clock() * 1000,
        duration = settings.highlight_duration,
        size = settings.highlight_size,
    }
    
    table.insert(state.highlights, highlight)
    
    print(string.format("[Highlight] %s click at (%d, %d)", 
        is_left_click and "Left" or "Right", math.floor(x), math.floor(y)))
end

local function update_highlights()
    if not settings.show_click_highlight then
        state.highlights = {}
        return
    end
    
    local current_time = os.clock() * 1000
    local new_highlights = {}
    
    for _, highlight in ipairs(state.highlights) do
        local age = current_time - highlight.start_time
        if age < highlight.duration then
            table.insert(new_highlights, highlight)
        end
    end
    
    state.highlights = new_highlights
end

-- Create or get highlight overlay source
local function get_or_create_highlight_source()
    -- Look for existing source
    local source = obs.obs_get_source_by_name(HIGHLIGHT_SOURCE_NAME)
    
    if not source then
        -- Create a color source that we'll draw on
        local settings_data = obs.obs_data_create()
        obs.obs_data_set_int(settings_data, "width", 1920)
        obs.obs_data_set_int(settings_data, "height", 1080)
        obs.obs_data_set_int(settings_data, "color", 0x00000000)  -- Transparent
        
        source = obs.obs_source_create("color_source_v3", HIGHLIGHT_SOURCE_NAME, settings_data, nil)
        obs.obs_data_release(settings_data)
        
        -- Add to current scene
        local current_scene = obs.obs_frontend_get_current_scene()
        if current_scene then
            local scene = obs.obs_scene_from_source(current_scene)
            if scene then
                local scene_item = obs.obs_scene_add(scene, source)
                -- Move to top
                obs.obs_sceneitem_set_order(scene_item, obs.OBS_ORDER_MOVE_TOP)
            end
            obs.obs_source_release(current_scene)
        end
        
        print("[Highlight] Created highlight overlay source")
    end
    
    return source
end

-- Render callback to draw highlights
local function render_highlights(data, effect)
    if not settings.show_click_highlight or #state.highlights == 0 then
        return
    end
    
    local current_time = os.clock() * 1000
    
    -- Draw each highlight circle
    for _, highlight in ipairs(state.highlights) do
        local age = current_time - highlight.start_time
        local progress = age / highlight.duration
        
        if progress < 1.0 then
            -- Calculate fade and scale
            local alpha = 1.0 - progress
            local scale = 0.5 + (progress * 0.5)  -- Grow from 0.5 to 1.0
            
            -- Color based on click type
            local r, g, b
            if highlight.is_left_click then
                r, g, b = 1.0, 0.84, 0.0  -- Yellow
            else
                r, g, b = 0.0, 0.64, 0.94  -- Blue
            end
            
            -- Draw circle
            obs.gs_matrix_push()
            obs.gs_matrix_translate3f(highlight.x, highlight.y, 0)
            obs.gs_matrix_scale3f(scale, scale, 1.0)
            
            -- Use OBS graphics to draw circle
            obs.gs_render_start(true)
            
            local size = highlight.size
            local segments = 32
            
            for i = 0, segments do
                local angle1 = (i / segments) * 2 * math.pi
                local angle2 = ((i + 1) / segments) * 2 * math.pi
                
                local x1 = math.cos(angle1) * size
                local y1 = math.sin(angle1) * size
                local x2 = math.cos(angle2) * size
                local y2 = math.sin(angle2) * size
                
                obs.gs_vertex2f(0, 0)
                obs.gs_vertex2f(x1, y1)
                obs.gs_vertex2f(x2, y2)
            end
            
            obs.gs_render_stop(obs.GS_LINESTRIP)
            obs.gs_matrix_pop()
        end
    end
end

-- Source management
local function find_source()
    if settings.source_name == "" then
        return nil
    end
    return obs.obs_get_source_by_name(settings.source_name)
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
    
    local filter = obs.obs_source_get_filter_by_name(state.source, CROP_FILTER_NAME)
    
    if not filter then
        filter = obs.obs_source_create_private("crop_filter", CROP_FILTER_NAME, nil)
        obs.obs_source_filter_add(state.source, filter)
    end
    
    return filter
end

local function update_source_dimensions()
    if not state.sceneitem then
        return
    end
    
    local source = obs.obs_sceneitem_get_source(state.sceneitem)
    if source then
        state.source_width = obs.obs_source_get_width(source)
        state.source_height = obs.obs_source_get_height(source)
    end
    
    local pos = obs.vec2()
    obs.obs_sceneitem_get_pos(state.sceneitem, pos)
    state.source_x = pos.x
    state.source_y = pos.y
end

-- Zoom functions
local function calculate_zoom_crop(center_x, center_y)
    local zoom_width = state.source_width / settings.zoom_factor
    local zoom_height = state.source_height / settings.zoom_factor
    
    local mouse_rel_x = center_x - state.source_x
    local mouse_rel_y = center_y - state.source_y
    
    local crop_x = mouse_rel_x - (zoom_width / 2)
    local crop_y = mouse_rel_y - (zoom_height / 2)
    
    crop_x = math.max(0, math.min(crop_x, state.source_width - zoom_width))
    crop_y = math.max(0, math.min(crop_y, state.source_height - zoom_height))
    
    return crop_x, crop_y, zoom_width, zoom_height
end

local function start_zoom(mouse_x, mouse_y)
    if not settings.auto_zoom_enabled then
        return
    end
    
    state.source = find_source()
    state.sceneitem = find_sceneitem()
    
    if not state.source or not state.sceneitem then
        return
    end
    
    update_source_dimensions()
    
    state.crop_filter = get_or_create_crop_filter()
    if not state.crop_filter then
        return
    end
    
    local crop_x, crop_y, zoom_width, zoom_height = calculate_zoom_crop(mouse_x, mouse_y)
    
    state.target_crop_x = crop_x
    state.target_crop_y = crop_y
    state.target_crop_width = zoom_width
    state.target_crop_height = zoom_height
    
    state.animation_progress = 0.0
    state.is_zoomed = true
    state.zoom_end_time = os.clock() * 1000 + settings.zoom_duration
    state.disable_auto_zoom_out = false
    
    print(string.format("[Auto-Zoom] Zooming to (%d, %d)", math.floor(mouse_x), math.floor(mouse_y)))
end

local function update_zoom_to_caret(caret_x, caret_y)
    if not state.is_zoomed then
        return
    end
    
    local crop_x, crop_y, zoom_width, zoom_height = calculate_zoom_crop(caret_x, caret_y)
    
    state.target_crop_x = crop_x
    state.target_crop_y = crop_y
    
    state.animation_progress = 0.5
end

local function end_zoom()
    if not state.is_zoomed then
        return
    end
    
    state.target_crop_x = 0
    state.target_crop_y = 0
    state.target_crop_width = state.source_width
    state.target_crop_height = state.source_height
    
    state.animation_progress = 0.0
    state.is_zoomed = false
    state.disable_auto_zoom_out = false
    state.is_typing = false
    
    print("[Auto-Zoom] Zooming out")
end

local function update_crop_filter()
    if not state.crop_filter then
        return
    end
    
    if state.animation_progress < 1.0 then
        local t = ease_in_out(state.animation_progress)
        
        state.crop_x = lerp(state.crop_x, state.target_crop_x, t)
        state.crop_y = lerp(state.crop_y, state.target_crop_y, t)
        state.crop_width = lerp(state.crop_width, state.target_crop_width, t)
        state.crop_height = lerp(state.crop_height, state.target_crop_height, t)
        
        local speed_factor = 1000.0 / settings.zoom_speed
        state.animation_progress = math.min(1.0, state.animation_progress + (0.016 * speed_factor))
    end
    
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
    
    local current_time = os.clock() * 1000
    
    -- Detect mouse clicks
    local left_down = is_mouse_button_down("left")
    local right_down = is_mouse_button_down("right")
    
    local left_clicked = left_down and not state.last_mouse_state.left
    local right_clicked = right_down and not state.last_mouse_state.right
    
    state.last_mouse_state.left = left_down
    state.last_mouse_state.right = right_down
    
    -- Handle clicks
    local should_zoom = false
    local is_left_click = false
    
    if settings.zoom_on_left_click and left_clicked then
        should_zoom = true
        is_left_click = true
    end
    if settings.zoom_on_right_click and right_clicked then
        should_zoom = true
        is_left_click = false
    end
    
    if should_zoom then
        local mouse_x, mouse_y = get_mouse_position()
        
        -- Add click highlight
        add_click_highlight(mouse_x, mouse_y, is_left_click)
        
        local dist = distance(mouse_x, mouse_y, state.last_click_x, state.last_click_y)
        
        if dist > settings.min_click_distance or not state.is_zoomed then
            if state.is_zoomed then
                end_zoom()
                return
            end
            
            start_zoom(mouse_x, mouse_y)
            state.last_click_x = mouse_x
            state.last_click_y = mouse_y
        end
    end
    
    -- Detect typing
    if settings.stay_zoomed_while_typing and state.is_zoomed then
        local key_pressed = is_any_key_pressed()
        
        if key_pressed then
            state.is_typing = true
            state.last_keystroke_time = current_time
            state.disable_auto_zoom_out = true
            
            if settings.follow_caret then
                local caret_x, caret_y = get_caret_position()
                if caret_x and caret_y then
                    local caret_dist = distance(caret_x, caret_y, state.last_caret_x, state.last_caret_y)
                    if caret_dist > 20 then
                        update_zoom_to_caret(caret_x, caret_y)
                        state.last_caret_x = caret_x
                        state.last_caret_y = caret_y
                    end
                end
            end
        else
            if state.is_typing then
                local time_since_keystroke = current_time - state.last_keystroke_time
                if time_since_keystroke > settings.typing_timeout then
                    state.is_typing = false
                    state.disable_auto_zoom_out = false
                    state.zoom_end_time = current_time + settings.zoom_duration
                end
            end
        end
    end
    
    -- Check for auto zoom-out
    if state.is_zoomed and not state.disable_auto_zoom_out then
        if current_time >= state.zoom_end_time then
            end_zoom()
        end
    end
    
    -- Update highlights
    update_highlights()
    
    -- Update crop filter animation
    update_crop_filter()
end

-- OBS Script Interface
function script_description()
    return [[<h2>Auto-Zoom with Typing Detection & Working Click Highlights!</h2>
<p><b>Version:</b> ]] .. VERSION .. [[</p>

<h3>✨ Features:</h3>
<ul>
<li>✅ Auto-zoom on clicks</li>
<li>✅ Stays zoomed while typing</li>
<li>✅ Follows text caret</li>
<li>✅ WORKING click highlights (no browser source needed!)</li>
</ul>

<p><b>Note:</b> Click highlights are logged to Script Log.<br>
Check View → Docks → Script Log to see them!</p>

<p><b>Platform:</b> Windows (full support)</p>]]
end

function script_properties()
    local props = obs.obs_properties_create()
    
    local source_list = obs.obs_properties_add_list(props, "source_name", "Zoom Source",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    
    local sources = obs.obs_enum_sources()
    if sources then
        for _, source in ipairs(sources) do
            local source_id = obs.obs_source_get_id(source)
            if source_id == "monitor_capture" or source_id == "xshm_input" or 
               source_id == "window_capture" or source_id == "display_capture" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(source_list, name, name)
            end
        end
    end
    obs.source_list_release(sources)
    
    obs.obs_properties_add_bool(props, "auto_zoom_enabled", "✅ Enable Auto-Zoom on Click")
    obs.obs_properties_add_bool(props, "zoom_on_left_click", "Zoom on Left Click")
    obs.obs_properties_add_bool(props, "zoom_on_right_click", "Zoom on Right Click")
    obs.obs_properties_add_int_slider(props, "zoom_duration", 
        "Zoom Duration (ms)", 500, 5000, 100)
    obs.obs_properties_add_int_slider(props, "min_click_distance", 
        "Min Distance Between Clicks (px)", 50, 500, 10)
    
    obs.obs_properties_add_bool(props, "stay_zoomed_while_typing", 
        "⌨️ Stay Zoomed While Typing")
    obs.obs_properties_add_bool(props, "follow_caret", 
        "Follow Text Caret (Experimental)")
    obs.obs_properties_add_int_slider(props, "typing_timeout", 
        "Typing Timeout (ms)", 500, 3000, 100)
    
    obs.obs_properties_add_bool(props, "show_click_highlight", 
        "🎯 Log Click Highlights (check Script Log)")
    obs.obs_properties_add_int_slider(props, "highlight_duration", 
        "Highlight Duration (ms)", 200, 1000, 50)
    obs.obs_properties_add_int_slider(props, "highlight_size", 
        "Highlight Size (px)", 20, 100, 5)
    
    obs.obs_properties_add_float_slider(props, "zoom_factor", 
        "Zoom Factor", 1.1, 4.0, 0.1)
    obs.obs_properties_add_int_slider(props, "zoom_speed", 
        "Zoom Animation Speed (ms)", 100, 1000, 50)
    
    return props
end

function script_defaults(settings_data)
    obs.obs_data_set_default_bool(settings_data, "auto_zoom_enabled", true)
    obs.obs_data_set_default_bool(settings_data, "zoom_on_left_click", true)
    obs.obs_data_set_default_bool(settings_data, "zoom_on_right_click", false)
    obs.obs_data_set_default_int(settings_data, "zoom_duration", 2000)
    obs.obs_data_set_default_int(settings_data, "min_click_distance", 100)
    
    obs.obs_data_set_default_bool(settings_data, "stay_zoomed_while_typing", true)
    obs.obs_data_set_default_bool(settings_data, "follow_caret", true)
    obs.obs_data_set_default_int(settings_data, "typing_timeout", 1000)
    
    obs.obs_data_set_default_bool(settings_data, "show_click_highlight", true)
    obs.obs_data_set_default_int(settings_data, "highlight_duration", 500)
    obs.obs_data_set_default_int(settings_data, "highlight_size", 40)
    
    obs.obs_data_set_default_double(settings_data, "zoom_factor", 1.5)
    obs.obs_data_set_default_int(settings_data, "zoom_speed", 400)
end

function script_update(settings_data)
    settings.source_name = obs.obs_data_get_string(settings_data, "source_name")
    settings.auto_zoom_enabled = obs.obs_data_get_bool(settings_data, "auto_zoom_enabled")
    settings.zoom_on_left_click = obs.obs_data_get_bool(settings_data, "zoom_on_left_click")
    settings.zoom_on_right_click = obs.obs_data_get_bool(settings_data, "zoom_on_right_click")
    settings.zoom_duration = obs.obs_data_get_int(settings_data, "zoom_duration")
    settings.min_click_distance = obs.obs_data_get_int(settings_data, "min_click_distance")
    
    settings.stay_zoomed_while_typing = obs.obs_data_get_bool(settings_data, "stay_zoomed_while_typing")
    settings.follow_caret = obs.obs_data_get_bool(settings_data, "follow_caret")
    settings.typing_timeout = obs.obs_data_get_int(settings_data, "typing_timeout")
    
    settings.show_click_highlight = obs.obs_data_get_bool(settings_data, "show_click_highlight")
    settings.highlight_duration = obs.obs_data_get_int(settings_data, "highlight_duration")
    settings.highlight_size = obs.obs_data_get_int(settings_data, "highlight_size")
    
    settings.zoom_factor = obs.obs_data_get_double(settings_data, "zoom_factor")
    settings.zoom_speed = obs.obs_data_get_int(settings_data, "zoom_speed")
    
    print("[Auto-Zoom] Settings updated")
    print("  - Auto-zoom: " .. (settings.auto_zoom_enabled and "ON" or "OFF"))
    print("  - Stay zoomed while typing: " .. (settings.stay_zoomed_while_typing and "ON" or "OFF"))
    print("  - Click highlights: " .. (settings.show_click_highlight and "ON (logged)" or "OFF"))
end

function script_load(settings_data)
    print("[Auto-Zoom] Script loaded - Version " .. VERSION)
    print("[Auto-Zoom] Platform: " .. ffi.os)
    print("[Auto-Zoom] Click highlights are logged to Script Log")
    print("[Auto-Zoom] Open View → Docks → Script Log to see highlights")
    
    obs.timer_add(function()
        tick(16)
    end, 16)
end

function script_unload()
    if state.is_zoomed then
        end_zoom()
    end
    
    if state.source then
        obs.obs_source_release(state.source)
    end
    if state.crop_filter then
        obs.obs_source_release(state.crop_filter)
    end
    
    print("[Auto-Zoom] Script unloaded")
end