object UniServerModule: TUniServerModule
  OldCreateOrder = False
  FilesFolder = 'files\'
  TempFolder = 'temp\'
  Title = 'UniGUI Deploy Manager'
  BGColor = 8404992
  CharSet = 'utf-8'
  FaviconOptions = [foVisible, foLocalCache]
  DefaultImageFormat = cfJpeg
  SuppressErrors = []
  UnavailableErrMsg = 'Server unavailable, please try later'
  LoadingMessage = 'Loading...'
  Bindings = <>
  ServerMessages.ExceptionTemplate.Strings = (
    '<html>'
    '<body bgcolor="#dfe8f6">'

      '<p style="text-align:center;color:#A05050">An Exception has occu' +
      'red in application:</p>'
    '<p style="text-align:center;color:#0000A0">[###message###]</p>'

      '<p style="text-align:center;color:#A05050"><a href="[###url###]"' +
      '>Restart application</a></p>'
    '</body>'
    '</html>')
  ServerMessages.InvalidSessionTemplate.Strings = (
    '<html>'
    '<body bgcolor="#dfe8f6">'
    '<p style="text-align:center;color:#0000A0">[###message###]</p>'

      '<p style="text-align:center;color:#A05050"><a href="[###url###]"' +
      '>Restart application</a></p>'
    '</body>'
    '</html>')
  ServerMessages.TerminateTemplate.Strings = (
    '<html>'
    '<body bgcolor="#dfe8f6">'
    '<p style="text-align:center;color:#0000A0">[###message###]</p>'

      '<p style="text-align:center;color:#A05050"><a href="[###url###]"' +
      '>Restart application</a></p>'
    '</body>'
    '</html>')
  ServerMessages.InvalidSessionMessage = 'Invalid session or session Timeout.'
  ServerMessages.TerminateMessage = 'Web session terminated.'
  ExtLocale = '[Auto]'
  Compression.MinTextSize = 512
  ServerLimits.MaxSessions = 100000
  SSL.SSLOptions.RootCertFile = 'root.pem'
  SSL.SSLOptions.CertFile = 'cert.pem'
  SSL.SSLOptions.KeyFile = 'key.pem'
  SSL.SSLOptions.Method = sslvTLSv1_1
  SSL.SSLOptions.SSLVersions = [sslvTLSv1_1]
  SSL.SSLOptions.Mode = sslmUnassigned
  SSL.SSLOptions.VerifyMode = []
  SSL.SSLOptions.VerifyDepth = 0
  ConnectionFailureRecovery.ErrorMessage = 'Connection Error'
  ConnectionFailureRecovery.RetryMessage = 'Retrying...'
  CustomCSS.Strings = (
    '<style type="text/css">'
    'body, .x-body { font-family: "Segoe UI", Roboto, -apple-system, Arial' +
      ', sans-serif !important; background:#ECF0F5 !important; }'

    '.dm-sidebar { background:#222D32 !important; }'
    '.dm-sidebar .x-panel-body { background: transparent !important; }'
    '.dm-sidebar-brand { background:#1A2226 !important; border-bottom:1px' +
      ' solid #1A2226 !important; }'
    '.dm-sidebar-brand .x-panel-body { background: transparent !important' +
      '; }'
    '.dm-nav-active { background:#1E282C !important; border-left:3px sol' +
      'id #3C8DBC !important; }'
    '.dm-nav-active .x-panel-body { background: transparent !important; }'

    '.dm-navbar { background:#ffffff !important; border-bottom:1px solid' +
      ' #D2D6DE !important; }'
    '.dm-navbar .x-panel-body { background: transparent !important; }'

    '.dm-box-header { background:#ffffff !important; border-bottom:1px s' +
      'olid #D2D6DE !important; }'
    '.dm-box-header .x-panel-body { background: transparent !important; }'

    '.x-grid-cell.x-theme-color { background:#F4F4F4 !important; border-' +
      'bottom:2px solid #3C8DBC !important; }'
    '.x-grid-cell.x-theme-color .x-grid-cell-inner { color:#444444 !impo' +
      'rtant; font-weight:600 !important; }'

    '.dm-login-window { border:none !important; box-shadow:0 1px 4px rgb' +
      'a(0,0,0,0.25) !important; }'
    '.dm-login-card { border-top:3px solid #3C8DBC !important; }'

    '.x-btn-button { border-radius:3px !important; }'
    '.dm-btn-primary .x-btn-button { background:#3C8DBC !important; bord' +
      'er-color:#367FA9 !important; }'
    '.dm-btn-primary .x-btn-inner { color:#fff !important; font-weight:6' +
      '00 !important; }'
    '.dm-btn-success .x-btn-button { background:#00A65A !important; bord' +
      'er-color:#008D4C !important; }'
    '.dm-btn-success .x-btn-inner { color:#fff !important; font-weight:6' +
      '00 !important; }'
    '.dm-btn-danger .x-btn-button { background:#DD4B39 !important; borde' +
      'r-color:#D73925 !important; }'
    '.dm-btn-danger .x-btn-inner { color:#fff !important; font-weight:60' +
      '0 !important; }'
    '.dm-btn-warning .x-btn-button { background:#F39C12 !important; bord' +
      'er-color:#E08E0B !important; }'
    '.dm-btn-warning .x-btn-inner { color:#fff !important; font-weight:6' +
      '00 !important; }'
    '.dm-btn-info .x-btn-button { background:#00C0EF !important; border-' +
      'color:#00ACD6 !important; }'
    '.dm-btn-info .x-btn-inner { color:#fff !important; font-weight:600 ' +
      '!important; }'
    '.dm-btn-navlight .x-btn-button { background:transparent !important;' +
      ' border:1px solid #D2D6DE !important; }'
    '.dm-btn-navlight .x-btn-inner { color:#444444 !important; }'
    '.dm-btn-navlight:hover .x-btn-button { background:#F4F4F4 !important' +
      '; }'

    '::-webkit-scrollbar { width:10px; height:10px; }'
    '::-webkit-scrollbar-thumb { background:#C7CBD1; border-radius:6px; }'
    '</style>')
  Height = 150
  Width = 215
end
