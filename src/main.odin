package main

import "hoi4"

import "core:log"
import glm "core:math/linalg/glsl"



main :: proc() {
	g: hoi4.GlobalState
	hoi4.globalState_init(&g, "game")
	defer hoi4.globalState_free(&g)
	context.logger = g.logger_backend

	hoi4.ideologies_make(&g.i, g)
	defer hoi4.ideologies_delete(&g.i)

	hoi4.map_make(&g.m, g)
	defer hoi4.map_delete(&g.m)

	win := hoi4.window_create(g, "name", {1280, 720}, {.VSync, .Debug})
	defer hoi4.window_close(win)

	hoi4.graphics_make(&g.gs, {1280, 720})
	hoi4.graphics_stateInit(&g.gs, g.m)
	defer hoi4.graphics_free(&g.gs)

	hoi4.window_show(win)

	g.player = hoi4.map_findCountry(g.m, "LIT")

	for !hoi4.window_isClosed(win) {
		state := hoi4.window_pollEvents(win)

		c := [2]f32{f32(state.mouse_pos.x), f32(state.mouse_pos.y)}

		/*if (.MouseScroll in win.events) && state.mouse_scroll.y != 0 {
			zoom: f32 = (state.mouse_scroll.y > 0) ? 1.05 : (1.0/1.05)
			shift := glm.mat4Translate({c.x, c.y, 0})
			scale := glm.mat4Scale({zoom, zoom, 0})
			shift_back := glm.mat4Translate({-c.x, -c.y, 0})
			g.gs.u_transform *= shift * scale * shift_back
			//gl.LineWidth(10.0)
		}*/

		loop: if .MousePress in win.events {
			c_4x := g.gs.u_transform * [4]f32{c.x, 720 - c.y, 0, 1}
			c_4x.x = (c_4x.x * 0.5 + 0.5) * 1280.0
			c_4x.y = (c_4x.y * 0.5 + 0.5) * 720.0
			clr := hoi4.map_getPixel(g.m, {int(c_4x.x), int(c_4x.y)})

			hoi4.shader_use(g.gs.shader_state)
			s := g.selected_state
			if s != nil {
				hoi4.graphics_stateSetColor(&g.gs, g.selected_state^, s.owner.color)
			}

			g.selected_state = g.m.states_LUT[clr]
			if g.selected_state == nil { break loop }

			s = g.selected_state
			hoi4.graphics_stateSetColor(&g.gs, g.selected_state^, clr)

			log.info("Clicked state: ", s)
			log.info("Clicked country: ", s.owner)
		}

		hoi4.graphics_render(&g.gs, g.m, {0.1, 0.2, 0.2, 1.0})
		hoi4.window_swapBuffers(win)
	}
}
