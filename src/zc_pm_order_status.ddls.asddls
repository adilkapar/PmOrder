@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Orsers Status History'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_PM_ORDER_STATUS as projection on  ZR_PM_ORDER_STATUS 
{
    key Objnr,
    key Stat,
    key Chgnr,
    MaintenanceOrder,
    Usnam,
    Udate, 
    Utime,
    Tcode,
    Cdtcode,
    Inact,
    Chind,
    StatusText,
    /* Associations */

     _Order : redirected to parent ZC_PM_ORDER
}