#if (CeeJay_PIGGY != 0)
	#ifndef CeeJay_PIGGY_COUNT_PONG
		#if (CeeJay_PIGGY_COUNT_PING > 0)
			#define CeeJay_PIGGY_COUNT_PONG (CeeJay_PIGGY_COUNT_PING - 1)
			#undef CeeJay_PIGGY_COUNT_PING
		#else
			#undef CeeJay_PIGGY
			#define CeeJay_PIGGY 0
			#undef CeeJay_PIGGY_COUNT_PING
		#endif
	#else
		#ifndef CeeJay_PIGGY_COUNT_PING
			#if (CeeJay_PIGGY_COUNT_PONG > 0)
				#define CeeJay_PIGGY_COUNT_PING (CeeJay_PIGGY_COUNT_PONG - 1)
				#undef CeeJay_PIGGY_COUNT_PONG
			#else
				#undef CeeJay_PIGGY
				#define CeeJay_PIGGY 0
				#undef CeeJay_PIGGY_COUNT_PONG
			#endif
		#endif
	#endif
#endif
