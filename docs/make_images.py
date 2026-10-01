from PIL import Image, ImageDraw, ImageFont
F="/usr/share/fonts/truetype/dejavu/"
def f(n,s): return ImageFont.truetype(F+n,s)
BG=(15,18,26); FG=(236,239,244); MUTED=(150,160,178); LEAD=(255,176,59); AGENT=(94,177,255); RED=(255,99,99); GREEN=(88,214,141); PANEL=(26,31,43); LINE=(55,63,80)

def rr(d,box,fill,outline=None,r=18,w=2): d.rounded_rectangle(box,r,fill=fill,outline=outline,width=w)
def ctext(d,cx,y,t,font,fill):
    w=d.textlength(t,font=font); d.text((cx-w/2,y),t,font=font,fill=fill)

# ---------- header 1400x700
im=Image.new("RGB",(1400,700),BG); d=ImageDraw.Draw(im)
d.text((80,70),"JUDGMENT SPLIT · iOS + CODING AGENTS",font=f("DejaVuSans-Bold.ttf",22),fill=MUTED)
d.text((80,115),"Keep the design.",font=f("DejaVuSans-Bold.ttf",72),fill=FG)
d.text((80,200),"Delegate the typing.",font=f("DejaVuSans-Bold.ttf",72),fill=LEAD)
# two columns
colY=340
rr(d,(80,colY,660,640),PANEL,LEAD)
d.text((110,colY+25),"LEAD WRITES",font=f("DejaVuSans-Bold.ttf",24),fill=LEAD)
for i,t in enumerate(["Interface seam","Invariants","Oracle","Failure-mode list"]):
    y=colY+80+i*52; d.ellipse((112,y+8,128,y+24),fill=LEAD); d.text((145,y),t,font=f("DejaVuSans.ttf",30),fill=FG)
rr(d,(740,colY,1320,640),PANEL,AGENT)
d.text((770,colY+25),"AGENT WRITES",font=f("DejaVuSans-Bold.ttf",24),fill=AGENT)
for i,t in enumerate(["Implementation","Most of the tests","Glue code"]):
    y=colY+80+i*52; d.ellipse((772,y+8,788,y+24),fill=AGENT); d.text((805,y),t,font=f("DejaVuSans.ttf",30),fill=FG)
d.text((770,colY+250),"checked by the lead's oracle",font=f("DejaVuSans-Oblique.ttf",22),fill=MUTED)
# arrow
d.line((670,490,728,490),fill=MUTED,width=4); d.polygon([(728,480),(740,490),(728,500)],fill=MUTED)
im.save("2026-10-01-judgment-split-header.png")

# ---------- diagram 1400x860
im=Image.new("RGB",(1400,860),BG); d=ImageDraw.Draw(im)
d.text((60,40),"Who designs the module?",font=f("DejaVuSans-Bold.ttf",40),fill=FG)
d.text((60,95),"Same feature, same agent. The difference is which artefacts a human authors.",font=f("DejaVuSans.ttf",22),fill=MUTED)
# left panel
rr(d,(60,150,660,800),PANEL,LINE)
d.text((90,175),"Whole-ticket delegation",font=f("DejaVuSans-Bold.ttf",28),fill=RED)
items=[("Interface seam","agent"),("Invariants","agent (or nobody)"),("Oracle","agent's own tests"),("Failure modes","not written down"),("Implementation","agent")]
for i,(a,b) in enumerate(items):
    y=240+i*62; rr(d,(90,y,630,y+50),(33,39,54),None,10)
    d.text((110,y+11),a,font=f("DejaVuSans.ttf",24),fill=FG); w=d.textlength(b,font=f("DejaVuSans.ttf",22)); d.text((610-w,y+13),b,font=f("DejaVuSans.ttf",22),fill=AGENT)
y=560; rr(d,(90,y,630,y+70),(60,30,34),RED,12)
ctext(d,360,y+10,"Senior: reviews the diff",font=f("DejaVuSans-Bold.ttf",24),fill=FG)
ctext(d,360,y+40,"after every decision is already made",font=f("DejaVuSans.ttf",20),fill=MUTED)
d.text((90,660),"Result: nobody on the team designed",font=f("DejaVuSans.ttf",22),fill=MUTED)
d.text((90,692),"the module. Review is the only check.",font=f("DejaVuSans.ttf",22),fill=MUTED)
# right panel
rr(d,(740,150,1340,800),PANEL,LINE)
d.text((770,175),"Judgment split",font=f("DejaVuSans-Bold.ttf",28),fill=GREEN)
items=[("Interface seam","lead"),("Invariants","lead"),("Oracle","lead"),("Failure modes","lead"),("Implementation","agent")]
for i,(a,b) in enumerate(items):
    y=240+i*62; rr(d,(770,y,1310,y+50),(33,39,54),None,10)
    col=LEAD if b=="lead" else AGENT
    d.text((790,y+11),a,font=f("DejaVuSans.ttf",24),fill=FG); w=d.textlength(b,font=f("DejaVuSans-Bold.ttf",22)); d.text((1290-w,y+13),b,font=f("DejaVuSans-Bold.ttf",22),fill=col)
y=560; rr(d,(770,y,1310,y+70),(24,52,40),GREEN,12)
ctext(d,1040,y+10,"Oracle runs every event sequence",font=f("DejaVuSans-Bold.ttf",24),fill=FG)
ctext(d,1040,y+40,"19,607 traces at depth 5",font=f("DejaVuSans.ttf",20),fill=MUTED)
d.text((770,660),"Returns the shortest counterexample:",font=f("DejaVuSans.ttf",22),fill=MUTED)
d.text((770,695),"confirmCart → tapPay → tapPay",font=f("DejaVuSansMono-Bold.ttf",22),fill=RED)
d.text((770,728),"= charged twice",font=f("DejaVuSansMono.ttf",22),fill=RED)
im.save("2026-10-01-judgment-split-diagram.png")

# ---------- code card 1400x900 (LinkedIn)
im=Image.new("RGB",(1400,900),BG); d=ImageDraw.Draw(im)
d.text((60,40),"Two lines that look fine in review",font=f("DejaVuSans-Bold.ttf",40),fill=FG)
d.text((60,98),"Agent-style first draft of a checkout reducer (constructed for the demo)",font=f("DejaVuSans.ttf",22),fill=MUTED)
rr(d,(60,150,1340,450),(22,26,36),LINE,14)
mono=f("DejaVuSansMono.ttf",26); monob=f("DejaVuSansMono-Bold.ttf",26)
KW=(198,120,221); TY=(97,175,239); CM=(110,120,140); ST=FG
lines=[
 [("// a second tap while the charge is in flight",CM)],
 [("case ",KW),("(.paying, .tapPay):",ST)],
 [("    return ",KW),("Transition",TY),("(.paying, effects: [.charge])",ST)],
 [("",ST)],
 [("// editing the cart abandons an in-flight charge",CM)],
 [("case ",KW),("(.paying, .editCart):",ST)],
 [("    return ",KW),("Transition",TY),("(.browsing)",ST)],
]
for i,segs in enumerate(lines):
    x=95; y=175+i*38
    for t,c in segs: d.text((x,y),t,font=mono,fill=c); x+=d.textlength(t,font=mono)
d.text((60,485),"The lead's oracle at depth 5: 19,607 traces, 3 invariants broken",font=f("DejaVuSans-Bold.ttf",28),fill=LEAD)
rr(d,(60,535,1340,840),(22,26,36),LINE,14)
out=[("FAIL  no-double-charge",RED),("      confirmCart → tapPay [charge] → tapPay [charge]",FG),("FAIL  charge-only-from-confirmed-cart   (same trace)",RED),("FAIL  paying-exits-only-on-outcome",RED),("      confirmCart → tapPay [charge] → editCart",FG),("At depth 2: PASS. Both bugs need three events.",MUTED)]
for i,(t,c) in enumerate(out): d.text((95,560+i*44),t,font=f("DejaVuSansMono.ttf",25),fill=c)
im.save("2026-10-01-judgment-split-code-card.png")
