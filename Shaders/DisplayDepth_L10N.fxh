/*
  DisplayDepth Translations
  Translation definitions for DisplayDepth.fx
*/

// Present Type UI

#if ADDON_ADJUST_DEPTH
	#define UI_PRESENT_TYPE_L10N_ADJUST_DEPTH "Adjust Depthアドオンのインストールを検出しました。\n"\
        "'設定に保存して反映する'ボタンをクリックすると、このエフェクトで調節した全ての変数が共通設定に反映されます。\n"\
        "または、上の'プリプロセッサの定義を編集'ボタンをクリックした後に開くダイアログで直接編集する事もできます。";
#else
	#define UI_PRESENT_TYPE_L10N_ADJUST_DEPTH "調節が終わったら、上の'プリプロセッサの定義を編集'ボタンをクリックした後に開くダイアログに入力する必要があります。\n"\
        "\n"\
        "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWNは現在" TEXT_UPSIDE_DOWN "に設定されています。\n"\
        "深度マップが上下逆さまに表示されている場合は" TEXT_UPSIDE_DOWN_ALTER "に変更して下さい。\n"\
        "\n"\
        "RESHADE_DEPTH_INPUT_IS_REVERSEDは現在" TEXT_REVERSED "に設定されています。\n"\
        "画面効果が深度マップのとき、近くの形状がより白く、遠くの形状がより黒い場合は" TEXT_REVERSED_ALTER "に変更して下さい。\n"\
        "また、法線マップで形が判別出来るが、深度マップが真っ暗に見えるという場合も、この設定の変更を試して下さい。\n"\
        "\n"\
        "RESHADE_DEPTH_INPUT_IS_LOGARITHMICは現在" TEXT_LOGARITHMIC "に設定されています。\n"\
        "画面効果に実際のレンダリングと合致しない縞模様がある場合は" TEXT_LOGARITHMIC_ALTER "に変更して下さい。";
#endif

#define UI_PRESENT_TYPE_L10N ui_label_ja_jp = "画面効果";\
		ui_items_ja_jp = "深度マップ\0法線マップ\0両方を表示 (左右分割)\0";\
		ui_tooltip_ja_jp = \
		"'深度マップ'は、形状の遠近を白黒で表現します。正しい見え方では、近くの形状ほど黒く、遠くの形状ほど白くなります。\n"\
		"'法線マップ'は、形状を滑らかに表現します。正しい見え方では、全体的に青緑風で、地平線を見たときに地面が緑掛かった色合いになります。\n"\
		"'両方を表示 (左右分割)'が選択された場合は、左に法線マップ、右に深度マップを表示します。";\
		ui_text_ja_jp = UI_PRESENT_TYPE_L10N_ADJUST_DEPTH

// Blend Depth UI
#define UI_SHOW_OFFSET_L10N ui_label_ja_jp = "透かし比較";\
		ui_tooltip_ja_jp = "補正作業を支援するために、画面効果を半透過で適用します。";

// Live Preview UI
#if ADDON_ADJUST_DEPTH
    #define UI_USE_LIVE_PREVIEW_L10N_ADJUST_DEPTH "設定の準備が出来たら、'設定に保存して反映する'ボタンをクリックしてから、このチェックボックスをオフにして下さい。"
#else
    #define UI_USE_LIVE_PREVIEW_L10N_ADJUST_DEPTH "設定の準備が出来たら、上の'プリプロセッサの定義を編集'ボタンをクリックした後に開くダイアログに入力して下さい。"
#endif

#define UI_USE_LIVE_PREVIEW_L10N ui_category_ja_jp = "基本的な補正";\
    	ui_label_ja_jp = "プリプロセッサの定義を無視 (補正プレビューをオン)";\
    	ui_tooltip_ja_jp =\
        "共通設定に保存されたプリプロセッサの定義ではなく、これより下のプレビュー設定を使用するには、これを有効にします。\n"\
		UI_USE_LIVE_PREVIEW_L10N_ADJUST_DEPTH \
        "\n\n"\
        "プレビューをオンにした場合と比較して画面効果がまったく同じになれば、正しく設定が反映されています。";

// Upside Down UI
#if ADDON_ADJUST_DEPTH
#define UI_UPSIDE_DOWN_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファの上下反転を修正";\
    ui_text_ja_jp =\
        "\n"\
        "項目にカーソルを合わせると、設定が必要な状況の説明が表示されます。";\
    ui_tooltip_ja_jp =\
        "深度マップが上下逆さまに表示されている場合は変更して下さい。";
#else
#define UI_UPSIDE_DOWN_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファの上下反転を修正";\
    ui_text_ja_jp =\
        "\n"\
        "項目にカーソルを合わせると、設定が必要な状況の説明と、プリプロセッサの定義が表示されます。";\
    ui_tooltip_ja_jp =\
        "深度マップが上下逆さまに表示されている場合は変更して下さい。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=値\n"\
        "定義値は次の通りです。オンの場合は1、オフの場合は0を指定して下さい。\n"\
        "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=1\n"\
        "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0";
#endif

// Reversed UI
#if ADDON_ADJUST_DEPTH
#define UI_REVERSED_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファの奥行反転を修正";\
    ui_tooltip_ja_jp =\
        "画面効果が深度マップのとき、近くの形状が明るく、遠くの形状が暗い場合は変更して下さい。\n"\
        "また、法線マップで形が判別出来るが、深度マップが真っ暗に見えるという場合も、この設定の変更を試して下さい。";
#else
#define UI_REVERSED_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファの奥行反転を修正";\
    ui_tooltip_ja_jp =\
        "画面効果が深度マップのとき、近くの形状が明るく、遠くの形状が暗い場合は変更して下さい。\n"\
        "また、法線マップで形が判別出来るが、深度マップが真っ暗に見えるという場合も、この設定の変更を試して下さい。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_INPUT_IS_REVERSED=値\n"\
        "定義値は次の通りです。オンの場合は1、オフの場合は0を指定して下さい。\n"\
        "RESHADE_DEPTH_INPUT_IS_REVERSED=1\n"\
        "RESHADE_DEPTH_INPUT_IS_REVERSED=0";
#endif

// Logarithmic UI
#if ADDON_ADJUST_DEPTH
#define UI_LOGARITHMIC_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファを対数分布として扱うように修正";\
    ui_tooltip_ja_jp =\
        "画面効果に実際のゲーム画面と合致しない縞模様がある場合は変更して下さい。";
#else
#define UI_LOGARITHMIC_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度バッファを対数分布として扱うように修正";\
    ui_tooltip_ja_jp =\
        "画面効果に実際のゲーム画面と合致しない縞模様がある場合は変更して下さい。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=値\n"\
        "定義値は次の通りです。オンの場合は1、オフの場合は0を指定して下さい。\n"\
        "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=1\n"\
        "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0";
#endif

// Scale UI
#if ADDON_ADJUST_DEPTH
#define UI_SCALE_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "拡大率";\
    ui_text_ja_jp =\
        "\n"\
        " * その他の補正 (不定形またはその他)\n"\
        "\n"\
        "これより下は、深度バッファが不定形など、特別なケース向けの設定です。\n"\
        "通常はこれより上の'基本的な補正'のみでほとんどのゲームに適合します。\n"\
        "また、これらの設定は画質の向上にはまったく役に立ちません。\n\n";\
    ui_tooltip_ja_jp =\
        "深度バッファの解像度がクライアント解像度と異なる場合に変更して下さい。\n"\
        "このスケール値は、深度バッファの解像度とクライアント解像度との単純な比率になります。\n"\
        "深度バッファの解像度が1280×720でクライアント解像度が1920×1080の場合、横の比率が1920÷1280、縦の比率が1080÷720となります。\n"\
        "計算した結果を設定すると、値はそれぞれX_SCALE=1.5、Y_SCALE=1.5となります。";
#else
#define UI_SCALE_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "拡大率";\
    ui_text_ja_jp =\
        "\n"\
        " * その他の補正 (不定形またはその他)\n"\
        "\n"\
        "これより下は、深度バッファが不定形など、特別なケース向けの設定です。\n"\
        "通常はこれより上の'基本的な補正'のみでほとんどのゲームに適合します。\n"\
        "また、これらの設定は画質の向上にはまったく役に立ちません。\n\n";\
    ui_tooltip_ja_jp =\
        "深度バッファの解像度がクライアント解像度と異なる場合に変更して下さい。\n"\
        "このスケール値は、深度バッファの解像度とクライアント解像度との単純な比率になります。\n"\
        "深度バッファの解像度が1280×720でクライアント解像度が1920×1080の場合、横の比率が1920÷1280、縦の比率が1080÷720となります。\n"\
        "計算した結果を設定すると、値はそれぞれX_SCALE=1.5、Y_SCALE=1.5となります。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_INPUT_X_SCALE=横の値\n"\
        "RESHADE_DEPTH_INPUT_Y_SCALE=縦の値\n"\
        "定義値は次の通りです。横の値はX_SCALE、縦の値はY_SCALEに指定して下さい。\n"\
        "RESHADE_DEPTH_INPUT_X_SCALE=1.0\n"\
        "RESHADE_DEPTH_INPUT_Y_SCALE=1.0";
#endif

// Offset UI
#if ADDON_ADJUST_DEPTH
#define UI_OFFSET_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "位置オフセット";\
    ui_tooltip_ja_jp =\
        "深度バッファにレンダリングされた物体の形状が画面効果と重なり合っていない場合に変更して下さい。\n"\
        "この値は、ピクセル単位で指定します。";
#else
#define UI_OFFSET_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "位置オフセット";\
    ui_tooltip_ja_jp =\
        "深度バッファにレンダリングされた物体の形状が画面効果と重なり合っていない場合に変更して下さい。\n"\
        "この値は、ピクセル単位で指定します。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=横の値\n"\
        "RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=縦の値\n"\
        "定義値は次の通りです。横の値はX_PIXEL_OFFSET、縦の値はY_PIXEL_OFFSETに指定して下さい。\n"\
        "RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=0.0\n"\
        "RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=0.0";
#endif

// Far Plane UI
#if ADDON_ADJUST_DEPTH
#define UI_FAR_PLANE_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "遠点距離";\
    ui_tooltip_ja_jp =\
        "深度マップの色合いが距離感と合致しない、法線マップの表面が平面に見える、などの場合に変更して下さい。\n"\
        "遠点距離を1000に設定すると、ゲームの描画距離が1000メートルであると見なします。\n\n"\
        "このプレビュー画面はあくまでプレビューであり、ほとんどの場合、深度バッファは深度マップの色数より遥かに高い精度で表現されています。\n"\
        "例えば、10m前後の距離の形状が純粋な黒に見えるからという理由で値を変更しないで下さい。";
#else
#define UI_FAR_PLANE_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "遠点距離";\
    ui_tooltip_ja_jp =\
        "深度マップの色合いが距離感と合致しない、法線マップの表面が平面に見える、などの場合に変更して下さい。\n"\
        "遠点距離を1000に設定すると、ゲームの描画距離が1000メートルであると見なします。\n\n"\
        "このプレビュー画面はあくまでプレビューであり、ほとんどの場合、深度バッファは深度マップの色数より遥かに高い精度で表現されています。\n"\
        "例えば、10m前後の距離の形状が純粋な黒に見えるからという理由で値を変更しないで下さい。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=値\n"\
        "定義値は次の通りです。\n"\
        "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=1000.0";
#endif

// Multiplier UI
#if ADDON_ADJUST_DEPTH
#define UI_MULTIPLIER_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度乗数";\
    ui_tooltip_ja_jp =\
        "特定のエミュレータソフトウェアにおける深度バッファを修正するため、特別に追加された変数です。\n"\
        "この値は僅かな変更でも計算式を破壊するため、設定すべき値を知らない場合は変更しないで下さい。";
#else
#define UI_MULTIPLIER_L10N ui_category_ja_jp = "基本的な補正";\
    ui_label_ja_jp = "深度乗数";\
    ui_tooltip_ja_jp =\
        "特定のエミュレータソフトウェアにおける深度バッファを修正するため、特別に追加された変数です。\n"\
        "この値は僅かな変更でも計算式を破壊するため、設定すべき値を知らない場合は変更しないで下さい。"\
        "\n\n"\
        "定義名は次の通りです。文字は完全に一致する必要があり、半角大文字の英字とアンダーバーを用いなければなりません。\n"\
        "RESHADE_DEPTH_MULTIPLIER=値\n"\
        "定義値は次の通りです。\n"\
        "RESHADE_DEPTH_MULTIPLIER=1.0";
#endif

// Technique UI
#if ADDON_ADJUST_DEPTH
#define UI_TECHNIQUE_L10N ui_tooltip_ja_jp =\
        "これは、深度バッファの入力をReShade側の計算式に合わせる調節をするための、設定作業の支援に特化した特殊な扱いのエフェクトです。\n"\
        "初期状態では「両方を表示」が選択されており、左に法線マップ、右に深度マップが表示されます。\n"\
        "\n"\
        "法線マップ(左側)は、形状を滑らかに表現します。正しい設定では、全体的に青緑風で、地平線を見たときに地面が緑を帯びた色になります。\n"\
        "深度マップ(右側)は、形状の遠近を白黒で表現します。正しい設定では、近くの形状ほど黒く、遠くの形状ほど白くなります。\n"\
        "\n"\
        "設定を完了するには、DisplayDepth.fxエフェクトの変数の一覧にある'設定に保存して反映する'ボタンをクリックして下さい。\n"\
        "すると、インストール先のゲームに対して共通の設定として保存され、他のプリセットでも正しく表示されるようになります。";
#else
#define UI_TECHNIQUE_L10N ui_tooltip_ja_jp =\
        "これは、深度バッファの入力をReShade側の計算式に合わせる調節をするための、設定作業の支援に特化した特殊な扱いのエフェクトです。\n"\
        "初期状態では「両方を表示」が選択されており、左に法線マップ、右に深度マップが表示されます。\n"\
        "\n"\
        "法線マップ(左側)は、形状を滑らかに表現します。正しい設定では、全体的に青緑風で、地平線を見たときに地面が緑を帯びた色になります。\n"\
        "深度マップ(右側)は、形状の遠近を白黒で表現します。正しい設定では、近くの形状ほど黒く、遠くの形状ほど白くなります。\n"\
        "\n"\
        "設定を完了するには、エフェクト変数の編集画面にある'プリプロセッサの定義を編集'ボタンをクリックした後に開くダイアログに入力して下さい。\n"\
        "すると、インストール先のゲームに対して共通の設定として保存され、他のプリセットでも正しく表示されるようになります。";
#endif