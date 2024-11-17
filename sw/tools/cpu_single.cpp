#include "cpu_common.h"
int main(int argc, char *argv[])
{
    int w = 1920, h = 1080;
    if(argc > 1)
        w = atoi(argv[1]);
    if(argc > 2)
        h = atoi(argv[2]);
    window canvas(h, w);
	canvas.show();

    gobjlist world;
    vector<material*> materials;
    vector<gobj*> gobjs;

    std::chrono::high_resolution_clock::time_point st, ed;
	std::chrono::duration<float, std::milli> duration;

    setup_scene(&world, &materials, &gobjs);
    
    st = std::chrono::high_resolution_clock::now();
    render_scene(&world, (unsigned char*)canvas.buffer, canvas.get_buffer_w(), canvas.get_buffer_h(), 16);
    ed = std::chrono::high_resolution_clock::now();
	duration = std::chrono::duration_cast<std::chrono::duration<float, std::milli>>(ed - st);
    std::cerr << duration.count() << std::endl;

    canvas.display(std::cout);
    canvas.wait_for_close();


    //cleanup
    for(material* i: materials)
        delete i;
    delete[] materials.data;
    for(gobj* i: gobjs)
        delete i;
    delete[] gobjs.data;

    return 0;
}
