import bodyParser from 'koa-bodyparser'
import Koa from 'koa'
import router from './routes'
import logger from './middleware/logger-middleware'

const app = new Koa()
app.use(logger())
app.use(bodyParser())
app.use(router.middleware())

export default app
