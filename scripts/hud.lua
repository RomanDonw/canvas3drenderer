function on_hud_open()
    hud.open_permanent(PACK_ID .. ":display")
end

function on_hud_render()
    events.emit(PACK_ID .. ":on_hud_render")
end
