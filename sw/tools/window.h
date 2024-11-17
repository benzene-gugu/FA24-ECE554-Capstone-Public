#ifndef WINDOW_H
#define WINDOW_H


#include <ostream>
#include <cstdio>
#ifdef DEBUG
#define DEBUG_PRINT(fmt, args...)    std::fprintf(stdout, fmt, ## args)
#else
#define DEBUG_PRINT(fmt, args...)    /* Don't do anything in release builds */
#endif


void write_ppm(std::ostream &ofs, int h, int w, const unsigned char *buf)
{
    ofs << "P3\n" << w << ' ' << h << "\n255\n";
    int off;
    for(int j = h - 1; j >= 0; --j)
    {
        off = 3*j*w;
        for(int i = 0; i < w; ++i)
        {
            int off2 = off + 3 * i;
            ofs << (unsigned int)buf[off2] << ' '
                << (unsigned int)buf[off2+1] << ' '
                << (unsigned int)buf[off2+2]<< '\n';
        }
    }
}

#ifdef ENABLE_GUI
#define DEBUG
#define GL_SILENCE_DEPRECATION

#ifdef __APPLE__
#include <GLFW/glfw3.h>
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#include "GLFW/glfw3.h"
#endif


class window
{
private:
	bool inited;
	GLFWwindow *win = nullptr;
	int width, height;
	int w_width, w_height;
public:
	GLubyte *buffer;
	int get_buffer_w()
	{
		return this->width;
	}
	int get_buffer_h()
	{
		return this->height;
	}

	window(int w_hei = 640, int w_wid = 640)
	{
		this->w_height = w_hei;
		this->w_width = w_wid;
		this->buffer = nullptr;
		if(!this->init())
			DEBUG_PRINT("%s\n", "ERROR on initializing GLFW.");
	}
	~window()
	{
		if(this->win) glfwDestroyWindow(this->win);
		glfwTerminate();
		if(this->buffer) delete[] this->buffer;
	}

	static void err(int erro, const char* desp)
	{
		DEBUG_PRINT("%s\n", desp);
	}

	bool init()
	{
		if(!glfwInit()) return false;

		glfwSetErrorCallback(err);
		this->win = glfwCreateWindow(this->w_width, this->w_height, "Window", NULL, NULL);
		if(!this->win) return false;

		glfwGetFramebufferSize(this->win, &this->width, &this->height);
		this->buffer = new GLubyte[this->width*this->height*3];
		glfwMakeContextCurrent(this->win);
		return this->inited = true;
	}

	void show()
	{
		glViewport(0, 0, width, height);
		glClearColor(0.0, 0.0, 0.0, 0);
		for(int x = 0; x < this->width; ++x)
			for(int y = 0; y < this->height; ++y)
			{
				int offset = 3*(y*this->width + x);
				this->buffer[offset] = 255*std::sqrt((double)(x*x+y*y)/(height*height + width*width));
				this->buffer[offset+1] = this->buffer[offset];
				this->buffer[offset+2] = this->buffer[offset];
				//DEBUG_PRINT("%d\n", this->buffer[offset]);
			}
		//while(!glfwWindowShouldClose(this->win))
		this->display();
	}

	void display(std::ostream &ofs)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glDrawPixels(this->width, this->height, GL_RGB, GL_UNSIGNED_BYTE, this->buffer);
		glfwSwapBuffers(this->win);
		glfwPollEvents();
	}
	void display()
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glDrawPixels(this->width, this->height, GL_RGB, GL_UNSIGNED_BYTE, this->buffer);
		glfwSwapBuffers(this->win);
		glfwPollEvents();
	}

	void wait_for_close()
	{
		while(!glfwWindowShouldClose(this->win))
		{
			this->display();
		}
	}

};
#else
class window
{
private:
	int width, height;
public:
	unsigned char *buffer;
	window(int w_hei = 640, int w_wid = 640)
	{
		this->height = w_hei;
		this->width = w_wid;
		this->buffer = new unsigned char[this->width*this->height*3];
	}
	int get_buffer_w()
	{
		return this->width;
	}
	int get_buffer_h()
	{
		return this->height;
	}
	void display(std::ostream &ofs) {write_ppm(ofs, this->height, this->width, this->buffer);}
	void wait_for_close() {}
	void init(){}
	void show(){}
	~window()
	{
		delete[] this->buffer;
	}

};
#endif


#endif
