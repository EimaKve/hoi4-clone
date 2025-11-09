package hoi4

import "core:log"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"



GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 3


Vertex :: struct {
	pos: glm.vec2,
}

GraphicsContext :: struct {
	state_program: u32,
	state_VAO: u32,

	state_VBO: u32,
	state_vertices: [dynamic]Vertex,

	state_IBO: u32,
	state_indirect_cmds: [dynamic]gl.DrawArraysIndirectCommand,

	state_uniforms: map[string]gl.Uniform_Info,

	u_color: [256]glm.vec4,
	u_color_loc: i32,

	u_transform: matrix[4, 4]f32
}


graphics_init :: proc(gs: ^GraphicsContext, window_res: [2]int) -> bool {
	gl_program, res := gl.load_shaders_source(
		#load("../../res/vertex_shader.glsl"), #load("../../res/fragment_shader.glsl")
	)
	if !res {
		log.errorf("Failed to load state shaders")
		return false
	}
	gs.state_program = gl_program

	gl.UseProgram(gs.state_program)

    gl.GenVertexArrays(1, &gs.state_VAO)
	gl.BindVertexArray(gs.state_VAO)

	buffers: [2]u32
    gl.GenBuffers(len(buffers), raw_data(buffers[:]))

	gs.state_VBO = buffers[0]
	gl.BindBuffer(gl.ARRAY_BUFFER, gs.state_VBO)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(gs.state_vertices) * size_of(gs.state_vertices[0]),
		raw_data(gs.state_vertices),
		gl.STATIC_DRAW
	)

	gs.state_IBO = buffers[1]
	gl.BindBuffer(gl.DRAW_INDIRECT_BUFFER, gs.state_IBO)
	gl.BufferData(
		gl.DRAW_INDIRECT_BUFFER,
		len(gs.state_indirect_cmds) * size_of(gs.state_indirect_cmds[0]),
		raw_data(gs.state_indirect_cmds),
		gl.STATIC_DRAW
	)

	// TODO(EimaMei): Make this autogen, check GB's code from discord
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
    gl.EnableVertexAttribArray(0)

	gs.state_uniforms = gl.get_uniforms_from_program(gs.state_program)
	gs.u_color_loc = gs.state_uniforms["u_color[0]"].location
	gl.Uniform4fv(
		gs.u_color_loc,
		i32(len(gs.state_indirect_cmds)),
		raw_data(&gs.u_color[0])
	)

	gl.Viewport(0, 0, i32(window_res.x), i32(window_res.y))
	gs.u_transform = glm.mat4Ortho3d(0, f32(window_res.x), f32(window_res.y), 0, 0, 1)

	return true
}

graphics_free :: proc(gs: ^GraphicsContext) {
	gl.destroy_uniforms(gs.state_uniforms)

	gl.DeleteProgram(gs.state_program)
	gl.DeleteVertexArrays(1, &gs.state_VAO)

	buffers := [2]u32{gs.state_VBO, gs.state_IBO}
    gl.DeleteBuffers(len(buffers), raw_data(buffers[:]))

	if (gs.state_indirect_cmds != nil) { delete(gs.state_indirect_cmds) }
	if (gs.state_vertices != nil) { delete(gs.state_vertices) }

	gs^ = {}
	log.infof("Freed graphics")
}

graphics_render :: proc(gs: ^GraphicsContext, bg: [4]f32) {
	gl.ClearColor(bg.r, bg.g, bg.b, bg.a)
    gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UniformMatrix4fv(gs.state_uniforms["u_transform"].location, 1, false, raw_data(&gs.u_transform))
    gl.BindVertexArray(gs.state_VAO)

	gl.MultiDrawArraysIndirect(gl.LINES, nil, i32(len(gs.state_indirect_cmds)), 0)
}


graphics_stateSetColor :: proc {
	graphics_stateSetColor_vec4,
	graphics_stateSetColor_color
}

graphics_stateSetColor_vec4 :: proc(gs: ^GraphicsContext, s: State, color: [4]f32) {
	gs.u_color[s.vertex_id] = color
	gl.Uniform4fv(
		gs.u_color_loc + i32(s.vertex_id), 1, raw_data(&gs.u_color[s.vertex_id])
	)
}

graphics_stateSetColor_color :: #force_inline proc(gs: ^GraphicsContext, s: State, color: Color) {
	clr := [4]f32{f32(color.r), f32(color.g), f32(color.b), 255}
	clr /= 255
	graphics_stateSetColor_vec4(gs, s, clr)
}


texture_make :: proc(data: ^u8, width, height, channels: int) -> (tex: u32) {
	@(static) internal_format_LUT := []i32{gl.R8, gl.RG8, gl.RGB8, gl.RGBA8}
	@(static) format_LUT := []u32{gl.RED, gl.RG, gl.RGB, gl.RGBA}

	gl.GenTextures(1, &tex)
	gl.BindTexture(gl.TEXTURE_2D, tex)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S,     gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T,     gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
	gl.PixelStorei(gl.UNPACK_ROW_LENGTH, i32(width))

	gl.TexImage2D(
		gl.TEXTURE_2D, 0, internal_format_LUT[channels - 1],
		i32(width), i32(height), 0, format_LUT[channels - 1],
		gl.UNSIGNED_BYTE, data
	)

	return
}
