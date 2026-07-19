--[[
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
]]

function on_hud_open()
    hud.open_permanent(PACK_ID .. ":display")
end

function on_hud_render()
    events.emit(PACK_ID .. ":on_hud_render")
end
