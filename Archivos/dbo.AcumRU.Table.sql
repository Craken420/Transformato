S E T   A N S I _ N U L L S   O F F  G O  S E T   Q U O T E D _ I D E N T I F I E R   O N  G O  C R E A T E   T A B L E   [ d b o ] . [ A c u m R U ] (  [ S u c u r s a l ]   [ i n t ]   N O T   N U L L ,  [ E m p r e s a ]   [ c h a r ] ( 5 )   N O T   N U L L ,  [ R a m a ]   [ c h a r ] ( 5 )   N O T   N U L L ,  [ E j e r c i c i o ]   [ i n t ]   N O T   N U L L ,  [ P e r i o d o ]   [ i n t ]   N O T   N U L L ,  [ M o n e d a ]   [ c h a r ] ( 1 0 )   N O T   N U L L ,  [ G r u p o ]   [ c h a r ] ( 1 0 )   N O T   N U L L ,  [ C u e n t a ]   [ c h a r ] ( 2 0 )   N O T   N U L L ,  [ S u b C u e n t a ]   [ v a r c h a r ] ( 2 0 )   N O T   N U L L ,  [ C a r g o s ]   [ m o n e y ]   N U L L ,  [ A b o n o s ]   [ m o n e y ]   N U L L ,  [ C a r g o s U ]   [ f l o a t ]   N U L L ,  [ A b o n o s U ]   [ f l o a t ]   N U L L ,  [ U l t i m o C a m b i o ]   [ d a t e t i m e ]   N U L L ,  C O N S T R A I N T   [ p r i A c u m R U ]   P R I M A R Y   K E Y   C L U S T E R E D  (  [ C u e n t a ]   A S C ,  [ S u b C u e n t a ]   A S C ,  [ G r u p o ]   A S C ,  [ R a m a ]   A S C ,  [ E j e r c i c i o ]   A S C ,  [ P e r i o d o ]   A S C ,  [ M o n e d a ]   A S C ,  [ S u c u r s a l ]   A S C ,  [ E m p r e s a ]   A S C ) W I T H   ( P A D _ I N D E X   =   O F F ,   S T A T I S T I C S _ N O R E C O M P U T E   =   O F F ,   I G N O R E _ D U P _ K E Y   =   O F F ,   A L L O W _ R O W _ L O C K S   =   O N ,   A L L O W _ P A G E _ L O C K S   =   O N )   O N   [ P R I M A R Y ] )   O N   [ P R I M A R Y ]  G O  A L T E R   T A B L E   [ d b o ] . [ A c u m R U ]   A D D   D E F A U L T   ( ( 0 ) )   F O R   [ S u c u r s a l ]  G O 