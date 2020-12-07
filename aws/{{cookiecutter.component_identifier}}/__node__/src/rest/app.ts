import bodyParser from 'koa-bodyparser'
import Koa from 'koa'
import winstonLogger from '../lib/logging'
import router from './routes'
import logger from './middleware/logger-middleware.ts'

const app = new Koa()

app.use(logger({ logger: winstonLogger }))
app.use(bodyParser())
app.use(router.middleware())

export default app
