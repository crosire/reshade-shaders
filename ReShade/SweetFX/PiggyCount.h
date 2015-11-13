#if (SFX_PIGGY != 0)
	#ifndef SFX_PIGGY_COUNT_PONG
		#if (SFX_PIGGY_COUNT_PING > 0)
			#define SFX_PIGGY_COUNT_PONG (SFX_PIGGY_COUNT_PING - 1)
			#undef SFX_PIGGY_COUNT_PING
		#else
			#undef SFX_PIGGY
			#define SFX_PIGGY 0
			#undef SFX_PIGGY_COUNT_PING
		#endif
	#else
		#ifndef SFX_PIGGY_COUNT_PING
			#if (SFX_PIGGY_COUNT_PONG > 0)
				#define SFX_PIGGY_COUNT_PING (SFX_PIGGY_COUNT_PONG - 1)
				#undef SFX_PIGGY_COUNT_PONG
			#else
				#undef SFX_PIGGY
				#define SFX_PIGGY 0
				#undef SFX_PIGGY_COUNT_PONG
			#endif
		#endif
	#endif
#endif