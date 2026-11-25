#pragma once
// Version 1 extension ABI. See godot/data/extension_layout.json. All values are
// integers, snapshots own clocks, and an all-zero table means legacy behavior.
namespace fight {
enum ActionParameter { XPolicy, XContactKind, XGroundLeft, XGroundBottom, XGroundRight, XGroundTop,
    XAirLeft, XAirBottom, XAirRight, XAirTop, XLowStart, XLowEnd, XPassStart, XPassEnd,
    XReface, XStopAtBody, XGroundedLift, XBleedDelay, XBleedStart, XBleedEnd,
    XCaptureFreeze, XPairTicks, XReleaseFreeze, XOwnerRecovery, XVictimRecovery,
    XReleaseGap, XThrowGrace, XTechTicks, XPairTrack, XFriction };
enum CharacterParameter { CPolicy, CBleedDuration, CBleedInitial, CBleedGrowth, CBleedInterval,
    CBleedBlockPercent, CBleedCap, CGroundSpeed, CAirSpeed, CCoastCap, CBackdashLock,
    CHalfWidth, CStanding, CCrouching, CAirBottom, CAirTop, CWalkStride, CRunStride };
constexpr int EXTENSION_FIELDS=714, CHARACTER_EXTENSION_FIELDS=947;
constexpr int XRoutes=30, XHurt=38, XPush=615, XRoot=656, XVertical=697;
constexpr int CProfiles=18, CPairTracks=783;
struct ActionExtension { int v[EXTENSION_FIELDS]; };
struct CharacterExtension { int v[CHARACTER_EXTENSION_FIELDS]; };
enum CaptureKind { StrikeContact, NormalCapture, CommandCapture, WoundCapture, LegacyCapture,
                   ImmediateCapture, GrapplerCapture, AntiAirCapture };
}
