@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'BM - Notification Partner (Child Entity)'


define view entity ZR_PM_ORDER_STATUS 
as select from ZV_PM_ORDER_STATUS_HIST as status
association to parent ZR_PM_ORDER as _Order on $projection.MaintenanceOrder = _Order.MaintenanceOrder
{
    key status.Objnr,
    key status.Stat,
    key status.Chgnr,
    status.MaintenanceOrder,
    status.Usnam,
    status.Udate,
    status.Utime,
    status.Tcode,
    status.Cdtcode,
    status.Inact,
    status.Chind,
    status.StatusText,
    /* Associations */
    _Order
}
