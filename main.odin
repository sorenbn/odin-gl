package main

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "vendor:glfw/bindings"

main :: proc()
{
	glfw.Init()

	// tell glfw we're trying to use this major/minor version of opengl
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	// use core profile version of opengl (not deprecated immediate-mode)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(1280, 720, "LearnOpenGL", nil, nil)

	if window == nil
	{
		fmt.println("ERROR: Failed to create GLFW window")
		glfw.Terminate()
		return
	}

	// make context of our window the main context on the current thread
	glfw.MakeContextCurrent(window)

	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 1200, 720)
	glfw.SetFramebufferSizeCallback(window, callback_window_resized)

	for !glfw.WindowShouldClose(window)
	{
		// input
		process_input(window)

		// rendering commands
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}

		// vertex buffer object
		vbo: u32
		// generate buffer
		gl.GenBuffers(1, &vbo)
		// bind it to ARRAY_BUFFER object
		gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
		// copy user data into the buffers memory
		gl.BufferData(
			gl.ARRAY_BUFFER,
			size_of(vertices),
			rawptr(&vertices[0]),
			gl.STATIC_DRAW,
		)

		// check and poll events
		glfw.PollEvents()
		// swap the back buffer with the front buffer and present it to the screen
		glfw.SwapBuffers(window)
	}

	glfw.Terminate()
}

process_input :: proc(window: glfw.WindowHandle)
{
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS
	{
		glfw.SetWindowShouldClose(window, true)
	}
}

callback_window_resized :: proc "c" (
	window: glfw.WindowHandle,
	width, height: i32,
)
{
	gl.Viewport(0, 0, width, height)
}
