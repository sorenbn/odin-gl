package textures

import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"

Shader :: struct {
	program_id: u32,
	vertex_id: u32,
	frag_id: u32
}

shader_create :: proc(vertex_path, frag_path: string) -> (Shader, bool) {
	load_ok: bool
	vert_id: u32

	vert_id, load_ok = shader_load_and_compile_shader(vertex_path, gl.VERTEX_SHADER)
	if !load_ok {
		fmt.println("ERROR: Unable to load and compile vertex shader")
		return Shader{}, false
	}

	frag_id: u32
	frag_id, load_ok = shader_load_and_compile_shader(frag_path, gl.FRAGMENT_SHADER)

	if !load_ok {
		fmt.println("ERROR: Unable to load and compile fragment shader")
		gl.DeleteShader(vert_id)
		return Shader{}, false
	}

	program_id: u32 = gl.CreateProgram()

	gl.AttachShader(program_id, vert_id)
	gl.AttachShader(program_id, frag_id)
	gl.LinkProgram(program_id)

	
	link_success: i32
	gl.GetProgramiv(program_id, gl.LINK_STATUS, &link_success)
	if link_success == 0 {
		log_size: i32
		gl.GetProgramiv(program_id, gl.INFO_LOG_LENGTH, &log_size)
		info_log := make([]u8, log_size)
		defer delete(info_log)
		written: i32
		gl.GetProgramInfoLog(program_id, log_size, &written, raw_data(info_log))
		fmt.eprintln("ERROR: Couldn't link shader program:", string(info_log[:written]))
		return Shader{}, false
	}
	
	// shaders are no longer needed after being linked
	gl.DeleteShader(frag_id)
	gl.DeleteShader(vert_id)
	
	return Shader {
		program_id = program_id,
		vertex_id = vert_id,
		frag_id = frag_id,
	}, true
}

shader_use :: proc(program_id: u32) {
	gl.UseProgram(program_id)
}

shader_destroy :: proc(program_id: u32) {
	gl.DeleteProgram(program_id)
}

shader_set_int :: proc(program_id: u32, name: cstring, value: i32) {
	gl.Uniform1i(gl.GetUniformLocation(program_id, name), value)
}

shader_set_float :: proc(program_id: u32, name: cstring, value: f32) {
	gl.Uniform1f(gl.GetUniformLocation(program_id, name), value)
}

shader_set_bool :: proc(program_id: u32, name: cstring, value: bool) {
	gl.Uniform1i(gl.GetUniformLocation(program_id, name), i32(value))
}

shader_load_and_compile_shader :: proc(path: string, type: u32) -> (u32, bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		fmt.println("ERROR: Could not read shader")
		return 0, false
	}
	defer delete(data)

	shader_id := gl.CreateShader(type)

	source := cstring(raw_data(data))
	source_length := i32(len(data))

	gl.ShaderSource(shader_id, 1, &source, &source_length)
	gl.CompileShader(shader_id)

	success: i32
	gl.GetShaderiv(shader_id, gl.COMPILE_STATUS, &success)

	if success == 0 {
		log_size: i32
		gl.GetShaderiv(shader_id, gl.INFO_LOG_LENGTH, &log_size)

		info_log := make([]u8, log_size)
		defer delete(info_log)

		written: i32
		gl.GetShaderInfoLog(shader_id, log_size, &written, raw_data(info_log))

		fmt.eprintln("ERROR: Couldn't compile shader:")
		fmt.eprintln(path)
		fmt.eprintln(string(info_log[:written]))

		gl.DeleteShader(shader_id)

		return 0, false
	}

	return shader_id, true
}
