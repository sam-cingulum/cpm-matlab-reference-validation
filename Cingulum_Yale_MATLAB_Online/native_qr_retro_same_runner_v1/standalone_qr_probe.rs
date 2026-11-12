//! Independent, source-free standalone Rust 2-column Householder QR research probe.
//! Retrospective on already-disclosed 48 cases; NOT certified MATLAB parity.
//! No private Cingulum source or MathWorks proprietary implementation imported.
use std::io::{self,BufRead};
fn norm(xs:&[f64])->f64{
 let mut scale=0.0_f64;let mut ssq=1.0_f64;
 for &z in xs{let a=z.abs();if a==0.0{continue}
  if scale<a{let r=scale/a;ssq=1.0+ssq*r*r;scale=a}
  else{let r=a/scale;ssq+=r*r}
 }
 if scale==0.0{0.0}else{scale*ssq.sqrt()}
}
fn reflector(v:&mut[f64])->Result<(f64,f64),String>{
 if v.is_empty(){return Err("empty reflector".into())}
 let alpha=v[0];let tailnorm=norm(&v[1..]);
 if tailnorm==0.0{v[0]=1.0;return Ok((alpha,0.0))}
 let beta=-alpha.hypot(tailnorm).copysign(alpha);
 let tau=(beta-alpha)/beta;let divisor=alpha-beta;
 if !beta.is_finite() || !tau.is_finite() || divisor==0.0 {return Err("QR reflector invalid".into())}
 for z in &mut v[1..]{*z/=divisor}
 v[0]=1.0;Ok((beta,tau))
}
fn apply(v:&[f64],tau:f64,c:&mut[f64]){
 if tau==0.0{return}
 let mut dot=c[0];
 for (&a,&b) in v[1..].iter().zip(&c[1..]){dot+=a*b}
 let weight=tau*dot;c[0]-=weight;
 for (&a,b) in v[1..].iter().zip(&mut c[1..]){*b-=a*weight}
}
fn qr(x:&[f64])->Result<([usize;2],[f64;4]),String>{
 let n=x.len();
 if n<10 || x.iter().any(|v|!v.is_finite()){return Err("invalid x".into())}
 let mut a=vec![1.0_f64;n];let mut b=x.to_vec();
 let pivot=if norm(&b)>norm(&a){std::mem::swap(&mut a,&mut b);[2,1]}else{[1,2]};
 let(r11,tau1)=reflector(&mut a)?;apply(&a,tau1,&mut b);
 let r12=b[0];let(r22,_tau2)=reflector(&mut b[1..])?;
 if !r11.is_finite() || !r22.is_finite() || r11==0.0 || r22==0.0{return Err("rank deficient".into())}
 let row=if pivot==[1,2]{[r11,r12,0.0,r22]}else{[r22,0.0,r12,r11]};
 Ok((pivot,row))
}
fn main()->Result<(),Box<dyn std::error::Error>>{
 let stdin=io::stdin();
 for line in stdin.lock().lines(){
  let line=line?;if line.trim().is_empty(){continue}
  let (id,blob)=line.split_once('\t').ok_or("malformed raw input TSV")?;
  if id.is_empty()||!id.bytes().all(|b|b.is_ascii_alphanumeric()||b==b'_'){return Err("invalid case id".into())}
  let x=blob.split(',').map(|v|{
   if v.len()!=16 || !v.bytes().all(|b|b.is_ascii_hexdigit()){return Err("invalid hex".to_string())}
   Ok(f64::from_bits(u64::from_str_radix(v,16).map_err(|e|e.to_string())?))
  }).collect::<Result<Vec<_>,String>>()?;
  let(pivot,r)=qr(&x)?;
  println!("{}\t{},{}\t{:016x},{:016x},{:016x},{:016x}",id,pivot[0],pivot[1],
   r[0].to_bits(),r[2].to_bits(),r[1].to_bits(),r[3].to_bits());
 }
 Ok(())
}
