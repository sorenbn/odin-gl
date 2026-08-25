package hello_triangle

import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "vendor:glfw/bindings"

main :: proc() {
	glfw.Init()

	// tell glfw we're trying to use this major/minor version of opengl
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	// use core profile version of opengl (not deprecated immediate-mode)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "LearnOpenGL", nil, nil)

	if window == nil {
		fmt.println("ERROR: Failed to create GLFW window")
		glfw.Terminate()
		return
	}

	// make context of our window the main context on the current thread
	glfw.MakeContextCurrent(window)

	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetFramebufferSizeCallback(window, callback_window_resized)

	// shader setup
	ok: bool
	vertex_shader_id: u32
	vertex_shader_id, ok = load_and_compile_shader(
		"vertex.vert",
		gl.VERTEX_SHADER,
	)

	if !ok {
		fmt.println("ERROR: Unable to load and compile vertex shader")
		return
	}

	fragment_shader_id: u32
	fragment_shader_id, ok = load_and_compile_shader(
		"fragment.frag",
		gl.FRAGMENT_SHADER,
	)

	if !ok {
		fmt.println("ERROR: Unable to load and compile fragment shader")
		return
	}

	shader_program_id: u32 = gl.CreateProgram()
	gl.AttachShader(shader_program_id, vertex_shader_id)
	gl.AttachShader(shader_program_id, fragment_shader_id)
	gl.LinkProgram(shader_program_id) // todo: program link error handling

	// shaders are not longer needed after being linked
	gl.DeleteShader(vertex_shader_id)
	gl.DeleteShader(fragment_shader_id)

	// left triangle
	vertices_triangle_1 := [?]f32 {
		-0.5,  0.25, 0.0,  // top center
		-0.25, -0.25, 0.0,  // bottom right
		-0.75, -0.25, 0.0,  // bottom left
	}

	// right triangle
	verticies_triangle_2 := [?]f32 {
		0.5,  0.25, 0.0,  // top center
		0.25, -0.25, 0.0,  // bottom right
		0.75, -0.25, 0.0,  // bottom left
	}

	// VBO: vertex-buffer-object (verticies data)
	// EBO: element-buffer-objet (indicies data)
	// VAO: vertex-array-object (object that stores the vertex attribute setup and EBO binding)
	vbo, vao: [2]u32
	// generate buffers
	gl.GenVertexArrays(2, &vao[0])
	gl.GenBuffers(2, &vbo[0])

	// bind vertex-array-object to tthe first triangle
	gl.BindVertexArray(vao[0])
	// bind it to ARRAY_BUFFER object
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo[0])
	// copy user data into the buffers memory
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices_triangle_1), &vertices_triangle_1[0], gl.STATIC_DRAW)
	// tell opengl how to intepret the vertex attribute at location 0 (aPos in vertex shader)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// bind vertex-array-object to tthe first triangle
	gl.BindVertexArray(vao[1])
	// bind it to ARRAY_BUFFER object
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo[1])
	// copy user data into the buffers memory
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verticies_triangle_2), &verticies_triangle_2[0], gl.STATIC_DRAW)
	// tell opengl how to intepret the vertex attribute at location 0 (aPos in vertex shader)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// draw in wire-frame mode
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// rendering commands
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program_id)

		// first triangle
		gl.BindVertexArray(vao[0])
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// second triangle
		gl.BindVertexArray(vao[1])
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// swap the back buffer with the front buffer and present it to the screen
		glfw.SwapBuffers(window)
		// check and poll events
		glfw.PollEvents()
	}

	gl.DeleteVertexArrays(2, &vao[0])
	gl.DeleteBuffers(2, &vbo[0])
	gl.DeleteProgram(shader_program_id)
	glfw.Terminate()
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

callback_window_resized :: proc "c" (
	window: glfw.WindowHandle,
	width, height: i32,
) {
	gl.Viewport(0, 0, width, height)
}

load_and_compile_shader :: proc(path: string, type: u32) -> (u32, bool) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		fmt.println("ERROR: Could not read vertex shader")
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
