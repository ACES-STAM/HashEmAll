/*
Reference Input and Output(in decimal):
Permutation - Input: [7, 5, 0]
Permutation - Output: [12360106593270449844061412657301362366573579256583003766552363058581964117186, 571281065699991603834232145226702411332243584689159097661681181035646779147, 5827211446942541137487801220137246525465448099690109106563675347241842025991]
Permutation - Input: [10917901770635866436075026016659080286184149548927087489003364430639471220657, 15093033869696199585334196511061284287566496673224764407232042360381732406822, 0]
Permutation - Output: [9015251630996607203618061446630382221872903244076542510604305929244679444419, 15879859090627996012910608502246148008395297925036347252664944182065690596621, 18560181493604561726790764277907035345951571022315713369595937606897153822615]
Permutation - Input: [21739712095178135048191546448963631920285197592697942392244793527788985886301, 8858283708315735321250403702432677061468885569337168495636056784571574406448, 0]
Permutation - Output: [18329931618415610668643634474014011335241935075190086161442182803215507500299, 2149369278479666633097953201825936302312307642502164003213072662610116947450, 1803625172765819007712227852553682169356933782067426899770176074186941360527]
Permutation - Input: [15647695940089500251678240681748798303434417819422794141800595102470224949797, 18478792838189852650095108189496860401827254585568628862804027353559861163985, 0]
Permutation - Output: [20486877510231618053066305798476308324104477256085821770670638367672575655972, 8506186614711587338271697025571522047350453599120149045311718895163873227158, 19331295163941894760549037142871984830693281730919883221311891988423964809664]
Permutation - Input: [19900524514612089806276604711837690453215070955832409975167381678422194897905, 1236606864354083188154591020243375615684840709595277385538149191988208506003, 0]
Permutation - Output: [15009369781091431499304070154912425359963382052464747391162946304596761648983, 17956993152787252927978581752944873836913007540812860576695818296736105965895, 20851007939158033029485606678152121739648672092401282804037817306968291308858]        
Permutation - Input: [20767081487668653306571970702982492773897412604424936666057505328864346471759, 5272159900800745762041740216767697914529812765717334033541487238715296148735, 0]
Permutation - Output: [20391782752823351916950710951584738593182576402115041728038492224577649332407, 21883934090929647172947679351779169281356816682663455117570507161160307800396, 17973598412196279653593606919328301226782415401620279915007894720105912403962]        
Permutation - Input: [9375207379161327853834308035010312852168568912774835926127390746572711653001, 18215294625592889596659303014994370765104507296543683038994134854673879109294, 0]
Permutation - Output: [19889201785444021530172424054140421604460547437976494848908655224396167553691, 5044671079490109332583090548905605047119878548832898313009479887641901576083, 1929933356026833760244198349596534755426312920563985950859654429696970425113]
Permutation - Input: [10442286909081447267778762487686955053420267485148173562551203049360125464309, 16414624291395617007545606219325363297485841380931547081432204698622829918059, 0]
Permutation - Output: [586931882465379973006570884560276388695335080962126786585334541594909638309, 10605590130054669982856577385566522123140177003613674829813146832297847874258, 12307656769483557841410822449766043069022688507182348556505429197287396560879]
Permutation - Input: [18837118988058782052907318170698452279560628312810076072342995247067701518258, 16705760111171223003951385386167643144584727294835379247504400984470192160688, 0]
Permutation - Output: [16596004394661610479122068598376906184305117752428815886081358879375591503791, 6741503635933551527107418409987439049104817672199007442045349756558814744489, 5558053279613392977281211721557313500134533314227567752367454852364877174955]
Permutation - Input: [5668094874103265696334551985640714133195387871229321113793698399566639512531, 5741960809815986019555904263416509216658722978137227432436430694971609592605, 0]
Permutation - Output: [20312383426545192611004893133874574752818372414797828357655346399368693793943, 4708829991803901504383743674115403649678177031808853369532565347040106996692, 12909228403971079314776936413852458583437435034074953780080402131569686453688]
Permutation - Input: [6087197294869114683777430443143440645720269033823964295565433563153171048140, 613784097092740180855052074166703620398728665939444412094895167860409273165, 0]
Permutation - Output: [11353501954590241139520956562143277668647705157009295084684059358521690511653, 4703085232975642147986339022696158401290520001257460041363588534276401671182, 8043069950384460949795636221448758395401471276227686134376467133418819805160]
Permutation - Input: [15456325924657491730148759865200832894571452057020814710844324085824832797932, 12266559940464367019075897177603685313945104910251119269749009731576014557555, 0]
Permutation - Output: [16682507527068287853940624795376103653397356963636959815185582131350975175551, 18897809649774000760636094983135481539778060017780735747681166112838742221360, 5754732557433427612157190016632686976712472482376761166933319574849245848156]
Permutation - Input: [1485130523526814394494219916554092458724911195344785758817920831066365205568, 10649320480001284802605218039042849994260571124891269262416666201188633701405, 0]
Permutation - Output: [19353883476287036883511347389610418528563609215800791665646647733738502746470, 12087580417395704682787375847542600002016002977387736481424707135723089961574, 1756968207129097057878199120117796069656823716921756986264483855510770593187]

Permutation - Input: [8290143119925711287876280136490249669582610229219973879991398449305759097152, 19290929958965935690410208288421628595961622243312948399111921512527180531651, 0]
Permutation - Output: [1077989441194811744808461001290952603345183168686113905632554826093981804818, 16365538413466499371028269021657946554802275635052803312908801525863402997582, 2871903975434744877093378747989627041347673140570493601106008461889984289892]
Permutation - Input: [4193168977688562206865178359682242615890164847570311539845158691956517557572, 15992158479564418332841358611023260734520607342818609040928120679758968139244, 0]
Permutation - Output: [17186551194449274759031447473386061067691209250404487384605642824554553683997, 2334109790881425544244054777227292718756915891271259298611518133329220932913, 6626529860487047909226761902626100765743741850269974157838152172230620590061]
Permutation - Input: [18126529567490462735337296262315838708487269530060116725064788538024240411043, 8293913026118979820369590800039573609850698647121098355559500785068759398841, 0]
Permutation - Output: [4278608790046265934251721744935200134232924401557094129901986897124855518353, 7240699545349843469773577281326064014179882868545359454465840112210070597148, 4035365344560974940214990239750496380333083231240667716472999793571556719991]
Permutation - Input: [18472633283626263301190348938180396322472516078499030539374886848334420702837, 1861777727398803111032275246803148308900471934494397032946967959491828062474, 0]
Permutation - Output: [19008093028586922362732202373284445133723033833960728131998832641050764457116, 10401291089459478683571702561375315369844532173044616882423693965475981020429, 305060800503315958790796568300117398545796462459564302545595012944983722308]
Permutation - Input: [21003795993605709978786462058900674173974984863495389773906720766151962589941, 5790947063318248384316313907639816261626075180576455626141062417776441930946, 0]
Permutation - Output: [16711618614747916928728264889177733269150240860973275953857571729515686392116, 891477987406735972913486784146884151834034116167119155317155830615952683079, 10058856019206763203111341802593085581522422563860663687612274815008154161855]
Permutation - Input: [17848984530841694944118709823830234363813351663137188506736482950977062880594, 14834397246125769327317071469657207817914717020772084742366375479883639443889, 0]
Permutation - Output: [12293911499013101061713544138738532553408464110440382855077862941691454047199, 5203862969434568639692477351771447661145840102593086431025864410157888396734, 443123797587574852869717363993148764254259969298381158206692103247215821345]
Permutation - Input: [7044044764114162882020434350212502112555238245157237356953179516604008394573, 2120266511375573878042473487717388843256365077043836149074934999603738487654, 0]
Permutation - Output: [68395870424426410443774242196076474045999814250800705533712438231003758594, 21665107767958475175820757838353319188271001884674514543622099087705398544414, 588780882455954792995479822473214891016194577431278130193119019888312407977]
Permutation - Input: [15521633289883278790835812181621084290075716305421059985796309505216914389687, 20627242347712424400608281311214276566544201212585966902916931523350268020905, 0]
Permutation - Output: [4604225620806716961011989588916453207130009974263325981692696904352980449055, 653733031294104301996227759242272910221454969067280720913329013519869605499, 1299511347503302399247618629768424955178599003180929545429470611938719624237]
Permutation - Input: [5697889606607744118707794951246471772042032182031933033784994646780267415218, 8177760010823906839106289724823483235535152426561234832327741788870543485003, 0]
Permutation - Output: [5671548909857699199205198975354648235779201291249576222962813366498592999020, 4247972601701449993496143017403918523093742511727200145077250762398480173215, 6147219741205490386861292722869142299570435401780958498817823237603481349479]
Permutation - Input: [10110591077288079406353279687274275223440488688917507526808486600914612379739, 7597637051456184238265898830297942641031835812039032107023362814135107048365, 0]
Permutation - Output: [8266315858322516170427765659238712516439188462903791986572168861045795004872, 12671975165049141482545159309009800938400991292363024390610624830260102537936, 19971375772959601412237454537614391501977769355679987278177052639899007713330]
Permutation - Input: [3172800489079168287273685480980239965124103766784635883437327819570125054571, 2176102977175494059250425691158358412563040184796706097594551260915497003601, 0]
Permutation - Output: [16025515286847343464111254345950267532968773644428454301670783200915160815612, 494945480095079939375941478768504601958925858064007796657511526930556354757, 8067882792547636276310362285829491839813776493446997666245314119727990353119]
Permutation - Input: [9983634557808795526896114270398735288943615470812596161346053601221253457639, 5772067626522549206917859556191407946042765812274824424111322991735853524904, 0]
Permutation - Output: [9556032886224726964742784744521906987870322822528229386466427051397847418936, 14767892246718499565228564452764546260810877137788532558628681968818306865704, 7498181378567936578191414004334002975319081062798828478025047398455090463673]
Permutation - Input: [18051945057134715441758942504511491190954606579709286528767718979678709981845, 3916220407122216137811197908418685793182338532358499006652486752884441602405, 0]
Permutation - Output: [2735754355502354140282095304225088989153463152655002627698336210059931965400, 2548066216023304895420859997341987606024960970131607643322521213270107119679, 14512207897230803921650390725658367083105710267473687453096418998227825733030]


*/

module tb_reinforcedConcrete_v2;

    parameter STATE_SIZE = 3;
    parameter N_BITS = 254;
    parameter PRIME_MODULUS = 254'h30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    parameter BARRETT_R = 255'h54a47462623a04a7ab074a58680730147144852009e880ae620703a6be1de925;

    logic clk, reset, enable;
    logic [N_BITS-1:0] inState1[STATE_SIZE][13];
    logic [N_BITS-1:0] inState2[STATE_SIZE][13];
    logic [N_BITS-1:0] outState1[STATE_SIZE][13];
    logic [N_BITS-1:0] outState2[STATE_SIZE][13];
    logic done;
  logic [N_BITS-1:0] testVector1[STATE_SIZE*13];
  logic [N_BITS-1:0] testVector2[STATE_SIZE*13];
    // Instantiate the DUT
    reinforcedConcrete_v2 #(
        .STATE_SIZE(STATE_SIZE),
        .N_BITS(N_BITS),
        .PRIME_MODULUS(PRIME_MODULUS),
        .BARRETT_R(BARRETT_R)
    ) dut (
        .inState1(inState1),
        .inState2(inState2),
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .outState1(outState1),
        .outState2(outState2),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Initialize inputs
        clk = 0;
        reset = 1;
        enable = 0;
      testVector1[0] = 254'd7;
testVector1[1] = 254'd5;
testVector1[2] = 254'd0;
testVector1[3] = 254'd10917901770635866436075026016659080286184149548927087489003364430639471220657;
testVector1[4] = 254'd15093033869696199585334196511061284287566496673224764407232042360381732406822;
testVector1[5] = 254'd0;
testVector1[6] = 254'd21739712095178135048191546448963631920285197592697942392244793527788985886301;
testVector1[7] = 254'd8858283708315735321250403702432677061468885569337168495636056784571574406448;
testVector1[8] = 254'd0;
testVector1[9] = 254'd15647695940089500251678240681748798303434417819422794141800595102470224949797;
testVector1[10] = 254'd18478792838189852650095108189496860401827254585568628862804027353559861163985;
testVector1[11] = 254'd0;
testVector1[12] = 254'd19900524514612089806276604711837690453215070955832409975167381678422194897905;
testVector1[13] = 254'd1236606864354083188154591020243375615684840709595277385538149191988208506003;
testVector1[14] = 254'd0;
testVector1[15] = 254'd20767081487668653306571970702982492773897412604424936666057505328864346471759;
testVector1[16] = 254'd5272159900800745762041740216767697914529812765717334033541487238715296148735;
testVector1[17] = 254'd0;
testVector1[18] = 254'd9375207379161327853834308035010312852168568912774835926127390746572711653001;
testVector1[19] = 254'd18215294625592889596659303014994370765104507296543683038994134854673879109294;
testVector1[20] = 254'd0;
testVector1[21] = 254'd10442286909081447267778762487686955053420267485148173562551203049360125464309;
testVector1[22] = 254'd16414624291395617007545606219325363297485841380931547081432204698622829918059;
testVector1[23] = 254'd0;
testVector1[24] = 254'd18837118988058782052907318170698452279560628312810076072342995247067701518258;
testVector1[25] = 254'd16705760111171223003951385386167643144584727294835379247504400984470192160688;
testVector1[26] = 254'd0;
testVector1[27] = 254'd5668094874103265696334551985640714133195387871229321113793698399566639512531;
testVector1[28] = 254'd5741960809815986019555904263416509216658722978137227432436430694971609592605;
testVector1[29] = 254'd0;
testVector1[30] = 254'd6087197294869114683777430443143440645720269033823964295565433563153171048140;
testVector1[31] = 254'd613784097092740180855052074166703620398728665939444412094895167860409273165;
testVector1[32] = 254'd0;
testVector1[33] = 254'd15456325924657491730148759865200832894571452057020814710844324085824832797932;
testVector1[34] = 254'd12266559940464367019075897177603685313945104910251119269749009731576014557555;
testVector1[35] = 254'd0;
testVector1[36] = 254'd1485130523526814394494219916554092458724911195344785758817920831066365205568;
testVector1[37] = 254'd10649320480001284802605218039042849994260571124891269262416666201188633701405;
testVector1[38] = 254'd0;
testVector2[0] = 254'd8290143119925711287876280136490249669582610229219973879991398449305759097152;
testVector2[1] = 254'd19290929958965935690410208288421628595961622243312948399111921512527180531651;
testVector2[2] = 254'd0;
testVector2[3] = 254'd4193168977688562206865178359682242615890164847570311539845158691956517557572;
testVector2[4] = 254'd15992158479564418332841358611023260734520607342818609040928120679758968139244;
testVector2[5] = 254'd0;
testVector2[6] = 254'd18126529567490462735337296262315838708487269530060116725064788538024240411043;
testVector2[7] = 254'd8293913026118979820369590800039573609850698647121098355559500785068759398841;
testVector2[8] = 254'd0;
testVector2[9] = 254'd18472633283626263301190348938180396322472516078499030539374886848334420702837;
testVector2[10] = 254'd1861777727398803111032275246803148308900471934494397032946967959491828062474;
testVector2[11] = 254'd0;
testVector2[12] = 254'd21003795993605709978786462058900674173974984863495389773906720766151962589941;
testVector2[13] = 254'd5790947063318248384316313907639816261626075180576455626141062417776441930946;
testVector2[14] = 254'd0;
testVector2[15] = 254'd17848984530841694944118709823830234363813351663137188506736482950977062880594;
testVector2[16] = 254'd14834397246125769327317071469657207817914717020772084742366375479883639443889;
testVector2[17] = 254'd0;
testVector2[18] = 254'd7044044764114162882020434350212502112555238245157237356953179516604008394573;
testVector2[19] = 254'd2120266511375573878042473487717388843256365077043836149074934999603738487654;
testVector2[20] = 254'd0;
testVector2[21] = 254'd15521633289883278790835812181621084290075716305421059985796309505216914389687;
testVector2[22] = 254'd20627242347712424400608281311214276566544201212585966902916931523350268020905;
testVector2[23] = 254'd0;
testVector2[24] = 254'd5697889606607744118707794951246471772042032182031933033784994646780267415218;
testVector2[25] = 254'd8177760010823906839106289724823483235535152426561234832327741788870543485003;
testVector2[26] = 254'd0;
testVector2[27] = 254'd10110591077288079406353279687274275223440488688917507526808486600914612379739;
testVector2[28] = 254'd7597637051456184238265898830297942641031835812039032107023362814135107048365;
testVector2[29] = 254'd0;
testVector2[30] = 254'd3172800489079168287273685480980239965124103766784635883437327819570125054571;
testVector2[31] = 254'd2176102977175494059250425691158358412563040184796706097594551260915497003601;
testVector2[32] = 254'd0;
testVector2[33] = 254'd9983634557808795526896114270398735288943615470812596161346053601221253457639;
testVector2[34] = 254'd5772067626522549206917859556191407946042765812274824424111322991735853524904;
testVector2[35] = 254'd0;
testVector2[36] = 254'd18051945057134715441758942504511491190954606579709286528767718979678709981845;
testVector2[37] = 254'd3916220407122216137811197908418685793182338532358499006652486752884441602405;
testVector2[38] = 254'd0;
        // Reset sequence
        #10;
        reset = 0;
        enable = 1;
      for (int i = 0; i < 13; i++) begin
        for(int j = 0; j < STATE_SIZE; j++) begin
          inState1[j][i] = testVector1[i*3+j];
          inState2[j][i] = testVector2[i*3+j];
        end
      end
        // Wait for done signal
        wait (done);
      $display("Permutation Complete.");
        #100 $finish;
    end
endmodule