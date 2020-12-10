import AWS from 'aws-sdk'

const client = new AWS.SecretsManager({
  region: process.env.AWS_REGION,
  endpoint:
    process.env.NODE_ENV !== 'production' ? new AWS.Endpoint('http://localhost:4566') : undefined,
})

export const getSecret = async (secretName: string): Promise<string> => {
  return new Promise((resolve, reject) => {
    client.getSecretValue({ SecretId: secretName }, (err, data) => {
      if (err) {
        console.error(err)
        return reject(err)
      }

      if (!data) {
        return reject(new Error('no data from secretsmanager'))
      }

      if (data.SecretString) return resolve(data.SecretString)

      if (data.SecretBinary) {
        let buff: Buffer
        if (typeof data.SecretBinary == 'string') {
          buff = Buffer.from(data.SecretBinary, 'base64')
        } else {
          buff = Buffer.from(data.SecretBinary)
        }
        return resolve(buff.toString('ascii'))
      }

      throw new Error(`Could not get string or binary secret for ${secretName}`)
    })
  })
}
