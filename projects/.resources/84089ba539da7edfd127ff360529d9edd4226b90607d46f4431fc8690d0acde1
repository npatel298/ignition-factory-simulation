# plant/sim.py  (Ignition 8.1, Jython 2.7)
from math import sin
import time

PROVIDER = "ProductionPlant"
TICK_SECONDS = 10.0  # your 10-second tick

def _p(*parts):
    """Build fully-qualified tag path: [Provider]Folder/Tag"""
    return "[%s]%s" % (PROVIDER, "/".join(parts))

def _rd(paths):
    return system.tag.readBlocking(paths)

def _wr(pairs):
    if not pairs:
        return
    system.tag.writeBlocking([p for p,_ in pairs], [v for _,v in pairs])

def step():
    t = time.time()
    updates = []

    # Tanks
    for tank in ("Tank1", "Tank2", "Tank3"):
        base = ("ReceivingArea", tank)
        lvl, tmp, valve, draw = _rd([
            _p(*(base + ("LevelPct",))),
            _p(*(base + ("TemperatureC",))),
            _p(*(base + ("OutletOpen",))),
            _p(*(base + ("MaxDrawLpm",))),
        ])
        temp_new = 22.0 + 3.0 * sin(t/60.0)
        draw_lpm = draw.value if (valve.value and lvl.value > 0.0) else 0.0
        lvl_new  = max(0.0, float(lvl.value) - float(draw_lpm) * 0.01)
        updates += [
            (_p(*(base + ("TemperatureC",))), temp_new),
            (_p(*(base + ("LevelPct",))), lvl_new),
        ]

    # Mixer inflow helper
    def mixer_inflow(sources):
        total = 0.0
        for src in sources:
            lvl, valve, draw = _rd([
                _p("ReceivingArea", src, "LevelPct"),
                _p("ReceivingArea", src, "OutletOpen"),
                _p("ReceivingArea", src, "MaxDrawLpm"),
            ])
            if valve.value and lvl.value > 0.2:
                total += min(float(draw.value), float(lvl.value) / 5.0)
        return total

    # Mixers
    m1_in = mixer_inflow(["Tank1", "Tank2"])
    m2_in = mixer_inflow(["Tank3"])
    for name, inflow in (("Mixer1", m1_in), ("Mixer2", m2_in)):
        base = ("BlendingArea", name)
        running, loss = _rd([
            _p(*(base + ("Running",))),
            _p(*(base + ("LossFactor",))),
        ])
        infl = float(inflow) if running.value else 0.0
        out  = (infl * (1.0 - float(loss.value))) if running.value else 0.0
        updates += [
            (_p(*(base + ("InflowLpm",))), infl),
            (_p(*(base + ("OutflowLpm",))), out),
        ]

    # Reactors
    for name, src in (("Reactor1", "Mixer1"), ("Reactor2", "Mixer2")):
        base = ("BlendingArea", name)
        T, P, rpm, hold = _rd([
            _p(*(base + ("TemperatureC",))),
            _p(*(base + ("PressureBar",))),
            _p(*(base + ("AgitatorRPM",))),
            _p(*(base + ("HoldUpLpm",))),
        ])
        infl = _rd([_p("BlendingArea", src, "OutflowLpm")])[0].value
        Tn = float(T.value) + 0.02 * float(infl) - 0.05 * (float(T.value) - 28.0)
        Pn = max(1.0, float(P.value) + 0.001 * float(infl) - 0.002 * (float(P.value) - 1.2))
        out = max(0.0, float(infl) - float(hold.value))
        updates += [
            (_p(*(base + ("InflowLpm",))), float(infl)),
            (_p(*(base + ("OutflowLpm",))), out),
            (_p(*(base + ("TemperatureC",))), Tn),
            (_p(*(base + ("PressureBar",))), Pn),
        ]

    # Fillers
    for name, src in (("Filler1", "Reactor1"), ("Filler2", "Reactor2")):
        base = ("PackagingArea", name)
        running, rate, count, vol = _rd([
            _p(*(base + ("Running",))),
            _p(*(base + ("RateBPM",))),
            _p(*(base + ("Count",))),
            _p(*(base + ("BottleVolumeL",))),
        ])
        feed = _rd([_p("BlendingArea", src, "OutflowLpm")])[0].value
        updates += [(_p(*(base + ("FeedLpm",))), float(feed))]
        if running.value:
            max_bpm_from_feed = (float(feed) / max(0.0001, float(vol.value))) if feed else 0.0
            actual_bpm = min(float(rate.value), max_bpm_from_feed)
            new_count = int(count.value + actual_bpm / 60.0 * TICK_SECONDS)
            updates += [(_p(*(base + ("Count",))), new_count)]

    # Inventory
    inv_base = ("InventoryArea", "Inventory")
    bpc = _rd([_p(*(inv_base + ("BottlesPerCase",)))])[0].value
    c1  = _rd([_p("PackagingArea", "Filler1", "Count")])[0].value
    c2  = _rd([_p("PackagingArea", "Filler2", "Count")])[0].value
    cases = int((int(c1) + int(c2)) // max(1, int(bpc)))
    updates += [(_p(*(inv_base + ("CasesOnHand",))), cases)]

    _wr(updates)