//
//  CoreWLANShim.m
//  iOS tools
//
//  Accès au RSSI réel via CoreWLAN, pour la version Mac Catalyst.
//
//  CoreWLAN est un framework public de macOS dont le binaire expose la cible
//  macabi (vérifiable dans son .tbd), mais dont les en-têtes sont annotés
//  « unavailable in Mac Catalyst » : le compilateur Swift refuse donc les appels
//  directs. On passe par le runtime Objective-C — uniquement des classes et
//  sélecteurs publics et documentés de CoreWLAN (CWWiFiClient, sharedWiFiClient,
//  interface, rssiValue, noiseMeasurement, transmitRate), chargés dynamiquement.
//

#include <TargetConditionals.h>

#if TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <dlfcn.h>

static id wlan_interface(void) {
    static void *handle = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        handle = dlopen("/System/Library/Frameworks/CoreWLAN.framework/CoreWLAN", RTLD_LAZY);
    });
    if (handle == NULL) return nil;
    Class cls = NSClassFromString(@"CWWiFiClient");
    if (cls == nil) return nil;
    id client = ((id (*)(id, SEL))objc_msgSend)(cls, sel_getUid("sharedWiFiClient"));
    if (client == nil) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(client, sel_getUid("interface"));
}

// RSSI en dBm ; 0 = pas de valeur (pas d'interface ou dissociée)
long wlan_rssi(void) {
    id itf = wlan_interface();
    if (itf == nil) return 0;
    return ((NSInteger (*)(id, SEL))objc_msgSend)(itf, sel_getUid("rssiValue"));
}

// Bruit en dBm ; 0 = pas de valeur
long wlan_noise(void) {
    id itf = wlan_interface();
    if (itf == nil) return 0;
    return ((NSInteger (*)(id, SEL))objc_msgSend)(itf, sel_getUid("noiseMeasurement"));
}

// Débit de transmission négocié en Mbit/s ; 0 = pas de valeur
double wlan_txrate(void) {
    id itf = wlan_interface();
    if (itf == nil) return 0;
    return ((double (*)(id, SEL))objc_msgSend)(itf, sel_getUid("transmitRate"));
}

#endif /* TARGET_OS_MACCATALYST */
