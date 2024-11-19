use crate::field::{Field, FieldElement};
use num_bigint::BigUint;
use std::str::FromStr;
use num_traits::One;

pub struct RescuePrime {
   pub  p: BigUint,
    pub field: Field,
    m: usize,
    rate: usize,
    capacity: usize,
    n: usize,
    alpha: BigUint,
    alphainv: BigUint,
    MDs: Vec<Vec<FieldElement>>,
    MDSinv: Vec<Vec<FieldElement>>,
    round_constants: Vec<FieldElement>,
}

impl RescuePrime {
    pub fn new() -> Self {
        // let p = BigUint::parse_bytes(b"2208397091110447631347581387072291226407", 10).unwrap();
        let pval = 407u128 * (1u128 << 119) + 1u128;
        let p = BigUint::from(pval);
        let m = 2;
        let rate = 1;
        let capacity = 1;
        let n = 27;
        let alpha = BigUint::from_str("3").unwrap();
        // let alphainv = BigUint::parse_bytes(b"180331931428153586757283157844700080811", 10).unwrap();
        let alphainv = BigUint::from_str("180331931428153586757283157844700080811").unwrap();
        let field = Field::new(p.clone());

        let MDs = vec![
            vec![FieldElement::new(BigUint::from_str("270497897142230380135924736767050121214").unwrap(), field.clone()), FieldElement::new(4u32.into(), field.clone())],
            vec![FieldElement::new(BigUint::from_str("270497897142230380135924736767050121205").unwrap(), field.clone()), FieldElement::new(13u32.into(), field.clone())],
        ];
        let MDSinv = vec![
            vec![FieldElement::new(BigUint::from_str("210387253332845851216830350818816760948").unwrap(), field.clone()), FieldElement::new(BigUint::from_str("60110643809384528919094385948233360270").unwrap(), field.clone())],
            vec![FieldElement::new(BigUint::from_str("90165965714076793378641578922350040407").unwrap(), field.clone()), FieldElement::new(BigUint::from_str("180331931428153586757283157844700080811").unwrap(), field.clone())],
        ];
        
    let round_constants = vec![
        FieldElement::new(BigUint::from_str("174420698556543096520990950387834928928").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("109797589356993153279775383318666383471").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("228209559001143551442223248324541026000").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("268065703411175077628483247596226793933").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("250145786294793103303712876509736552288").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("154077925986488943960463842753819802236").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("204351119916823989032262966063401835731").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("57645879694647124999765652767459586992").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("102595110702094480597072290517349480965").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("8547439040206095323896524760274454544").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("50572190394727023982626065566525285390").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("87212354645973284136664042673979287772").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("64194686442324278631544434661927384193").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("23568247650578792137833165499572533289").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("264007385962234849237916966106429729444").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("227358300354534643391164539784212796168").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("179708233992972292788270914486717436725").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("102544935062767739638603684272741145148").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("65916940568893052493361867756647855734").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("144640159807528060664543800548526463356").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("58854991566939066418297427463486407598").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("144030533171309201969715569323510469388").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("264508722432906572066373216583268225708").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("22822825100935314666408731317941213728").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("33847779135505989201180138242500409760").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("146019284593100673590036640208621384175").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("51518045467620803302456472369449375741").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("73980612169525564135758195254813968438").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("31385101081646507577789564023348734881").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("270440021758749482599657914695597186347").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("185230877992845332344172234234093900282").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("210581925261995303483700331833844461519").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("233206235520000865382510460029939548462").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("178264060478215643105832556466392228683").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("69838834175855952450551936238929375468").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("75130152423898813192534713014890860884").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("59548275327570508231574439445023390415").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("43940979610564284967906719248029560342").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("95698099945510403318638730212513975543").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("77477281413246683919638580088082585351").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("206782304337497407273753387483545866988").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("141354674678885463410629926929791411677").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("19199940390616847185791261689448703536").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("177613618019817222931832611307175416361").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("267907751104005095811361156810067173120").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("33296937002574626161968730356414562829").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("63869971087730263431297345514089710163").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("200481282361858638356211874793723910968").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("69328322389827264175963301685224506573").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("239701591437699235962505536113880102063").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("17960711445525398132996203513667829940").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("219475635972825920849300179026969104558").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("230038611061931950901316413728344422823").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("149446814906994196814403811767389273580").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("25535582028106779796087284957910475912").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("93289417880348777872263904150910422367").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("4779480286211196984451238384230810357").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("208762241641328369347598009494500117007").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("34228805619823025763071411313049761059").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("158261639460060679368122984607245246072").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("65048656051037025727800046057154042857").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("134082885477766198947293095565706395050").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("23967684755547703714152865513907888630").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("8509910504689758897218307536423349149").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("232305018091414643115319608123377855094").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("170072389454430682177687789261779760420").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("62135161769871915508973643543011377095").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("15206455074148527786017895403501783555").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("201789266626211748844060539344508876901").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("179184798347291033565902633932801007181").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("9615415305648972863990712807943643216").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("95833504353120759807903032286346974132").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("181975981662825791627439958531194157276").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("267590267548392311337348990085222348350").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("49899900194200760923895805362651210299").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("89154519171560176870922732825690870368").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("265649728290587561988835145059696796797").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("140583850659111280842212115981043548773").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("266613908274746297875734026718148328473").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("236645120614796645424209995934912005038").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("265994065390091692951198742962775551587").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("59082836245981276360468435361137847418").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("26520064393601763202002257967586372271").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("108781692876845940775123575518154991932").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("138658034947980464912436420092172339656").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("45127926643030464660360100330441456786").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("210648707238405606524318597107528368459").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("42375307814689058540930810881506327698").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("237653383836912953043082350232373669114").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("236638771475482562810484106048928039069").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("168366677297979943348866069441526047857").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("195301262267610361172900534545341678525").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("2123819604855435621395010720102555908").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("96986567016099155020743003059932893278").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("248057324456138589201107100302767574618").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("198550227406618432920989444844179399959").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("177812676254201468976352471992022853250").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("211374136170376198628213577084029234846").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("105785712445518775732830634260671010540").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("122179368175793934687780753063673096166").unwrap(), field.clone()),

        FieldElement::new(BigUint::from_str("126848216361173160497844444214866193172").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("22264167580742653700039698161547403113").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("234275908658634858929918842923795514466").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("189409811294589697028796856023159619258").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("75017033107075630953974011872571911999").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("144945344860351075586575129489570116296").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("261991152616933455169437121254310265934").unwrap(), field.clone()),
        FieldElement::new(BigUint::from_str("18450316039330448878816627264054416127").unwrap(), field.clone()),

    ];

        RescuePrime { 
            p,
            field,
            m,
            rate,
            capacity,
            n,
            alpha,
            alphainv,
            MDs,
            MDSinv,
            round_constants,
        }
    }

    pub fn hash( &self, input_element:FieldElement) -> FieldElement{
        let mut state = vec![self.field.zero(); self.m];
        state[0] = input_element;
        // println!("start state[{}] - {}", 0, state[0].clone().to_string());
        // println!("start state[{}] - {}", 1, state[1].clone().to_string());

        // Permutation phase
        for r in 0..self.n {
        //     // Forward half-round S-box
            for i in 0..self.m {
                state[i] = state[i].clone().pow(self.alpha.clone());
                // println!("state[{}] - {}", i, state[i].to_string());
            }
            
            // Matrix multiplication
            let mut temp = vec![self.field.zero(); self.m];
            for i in 0..self.m {
                for j in 0..self.m {
                    let mult_val = self.MDs[i][j].multiply(&state[j]);
                    temp[i] = temp[i].add(&mult_val);
                }
            }
            // Add round constants
            for i in 0..self.m {
                state[i] = temp[i].add(&self.round_constants[2 * r * self.m + i]);
            }

            // Backend half-round S-box
            for i in 0..self.m {
                state[i] = state[i].clone().pow(self.alphainv.clone());
            }
            // Matrix multiplication
            let mut temp = vec![self.field.zero(); self.m];
            for i in 0..self.m {
                for j in 0..self.m {
                    let mult_val = self.MDs[i][j].multiply(&state[j]);
                    temp[i] = temp[i].add(&mult_val);
                }
            }
            // Add round constants
            for i in 0..self.m {
                state[i] = temp[i].add(&self.round_constants[2 * r * self.m + self.m + i]);
            }
        }

        state[0].clone()
    }
}
