import { zhCN } from '../../i18n/zh-CN'
import { Step3Header } from './panelsBase'

export function Step3MissingJobId(props: { onRedeem: () => void }) {
  return (
    <div className="view-fade">
      <Step3Header />
      <div className="panel">
        <div className="panel-body">
          <div style={{ fontWeight: 600, marginBottom: 6 }}>{zhCN.step3.missingJobIdTitle}</div>
          <div className="inline-hint">{zhCN.step3.missingJobIdHint}</div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
            <button className="btn btn-primary" type="button" onClick={props.onRedeem}>
              {zhCN.step3.backToStep1}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

