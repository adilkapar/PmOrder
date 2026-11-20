@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material VH filtered by Order Plant'
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED }
define view entity ZV_PM_ORDER_MATERIAL
  as select from I_MaterialPlant as m
    inner join I_MaintenanceOrder as o
      on o.MaintenancePlanningPlant = m.Plant
    inner join I_MaterialText as t
      on  t.Material = m.Material
      and t.Language = $session.system_language
    inner join I_Material as mat
      on mat.Material = m.Material
{
  key o.MaintenanceOrder,
  key m.Material,
      m.Plant,
      t.MaterialName,
      mat.MaterialType
}
