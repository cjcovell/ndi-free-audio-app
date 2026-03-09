#include <cstdio>
#include <chrono>
#include <Processing.NDI.Lib.h>

int main(int argc, char* argv[])
{
	if (!NDIlib_initialize())
		return 1;

	NDIlib_find_instance_t pNDI_find = NDIlib_find_create_v2();
	if (!pNDI_find)
		return 1;

	// Scan for up to 5 seconds
	using namespace std::chrono;
	for (const auto start = high_resolution_clock::now(); high_resolution_clock::now() - start < seconds(5);) {
		NDIlib_find_wait_for_sources(pNDI_find, 1000);

		uint32_t no_sources = 0;
		const NDIlib_source_t* p_sources = NDIlib_find_get_current_sources(pNDI_find, &no_sources);

		if (no_sources > 0) {
			for (uint32_t i = 0; i < no_sources; i++)
				printf("%s\n", p_sources[i].p_ndi_name);
		}
	}

	// Final check
	uint32_t no_sources = 0;
	const NDIlib_source_t* p_sources = NDIlib_find_get_current_sources(pNDI_find, &no_sources);
	if (no_sources > 0) {
		for (uint32_t i = 0; i < no_sources; i++)
			printf("%s\n", p_sources[i].p_ndi_name);
	}

	NDIlib_find_destroy(pNDI_find);
	NDIlib_destroy();
	return 0;
}
