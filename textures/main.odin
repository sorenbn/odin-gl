package textures

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbi "vendor:stb/image"

main :: proc() {
	if !glfw.Init() {
		fmt.eprintln("ERROR: Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	// tell glfw we're trying to use this major/minor version of opengl
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	// use core profile version of opengl (not deprecated immediate-mode)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	stbi.set_flip_vertically_on_load(1)

	window := glfw.CreateWindow(800, 600, "LearnOpenGL", nil, nil)

	if window == nil {
		fmt.println("ERROR: Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)

	// make context of our window the main context on the current thread
	glfw.MakeContextCurrent(window)

	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetFramebufferSizeCallback(window, callback_window_resized)

	shader, ok := shader_create("vertex.vert", "fragment.frag")
	if !ok {
		fmt.println("ERROR: Failed to create shader.")
		return
	}
	defer shader_destroy(shader.program_id)

	vertices := [?]f32 {
		// positions       // texture coords
		 0.5,  0.5, 0.0,    1.0, 1.0, // top right
		 0.5, -0.5, 0.0,    1.0, 0.0, // bottom right
		-0.5, -0.5, 0.0,    0.0, 0.0, // bottom left
		-0.5,  0.5, 0.0,    0.0, 1.0, // top left
	}

	indices := [?]u32 {
		0, 1, 3, // first triangle
		1, 2, 3, // second triangle
	}

	// VBO: vertex-buffer-object (vertex data)
	// EBO: element-buffer-object (index data)
	// VAO: vertex-array-object (object that stores the vertex attribute setup and EBO binding)
	vbo, vao, ebo: u32
	// generate buffers
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)
	defer gl.DeleteBuffers(1, &ebo)

	// configure the rectangle's vertex attributes and index buffer
	gl.BindVertexArray(vao)
	// bind it to ARRAY_BUFFER object
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	// copy user data into the buffers memory
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// texture coord attribute
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	texture_id, texture_ok := load_texture("container.jpg")
	if !texture_ok {
		return
	}
	defer gl.DeleteTextures(1, &texture_id)

	texture_id_2, texture_2_ok := load_texture("wall.jpg")
	if !texture_2_ok {
		return
	}
	defer gl.DeleteTextures(1, &texture_id_2)

	shader_use(shader.program_id)
	shader_set_int(shader.program_id, "texture1", 0)
	shader_set_int(shader.program_id, "texture2", 1)
	
	gl.ClearColor(0.2, 0.3, 0.3, 1.0)

	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// rendering commands
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// bind each image to the unit assigned to its shader sampler
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture_id)

		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, texture_id_2)

		shader_use(shader.program_id)

		// draw the rectangle's two triangles
		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		// swap the back buffer with the front buffer and present it to the screen
		glfw.SwapBuffers(window)
		// check and poll events
		glfw.PollEvents()
	}
}

load_texture :: proc(path: cstring) -> (u32, bool) {
	width, height, nr_channels: i32
	// Request RGBA so the upload format is consistent and rows are 4-byte aligned.
	image_data := stbi.load(path, &width, &height, &nr_channels, 4)
	if image_data == nil {
		fmt.eprintln("ERROR: Could not load texture:", path, stbi.failure_reason())
		return 0, false
	}
	defer stbi.image_free(image_data)

	texture_id: u32
	gl.GenTextures(1, &texture_id)
	gl.BindTexture(gl.TEXTURE_2D, texture_id)

	// Wrapping defaults to REPEAT, and magnification filtering defaults to LINEAR.
	// This minification filter needs the mipmaps generated after the upload.
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image_data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return texture_id, true
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
